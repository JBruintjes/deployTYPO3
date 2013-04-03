class Typo3Helper

	def self.get_typo3_versions
		source = "http://sourceforge.net/api/file/index/project-id/20391/mtime/desc/rss"
		content = "" # raw content of rss feed will be loaded here
		open(source) do |s| content = s.read end
		rss = RSS::Parser.parse(content, false)

		#print "RSS title: ", rss.channel.title, "\n"
		#print "RSS link: ", rss.channel.link, "\n"
		#print "RSS description: ", rss.channel.description, "\n"
		#print "RSS publication date: ", rss.channel.date, "\n"

		#puts "Item values"
		
		_version_arr= []
		rss.items.each { |item|
			if item.title[0,24] =='/TYPO3 Source and Dummy/' 
				_item = item.title[24,1000].split(/\//)
				_version_arr << _item[0]
			end
		}
		return_string = ""
		version_arr = _version_arr.uniq.sort
		version_arr.each { |v|
			return_string << "version: "+ v+ "\n"
		}
		return return_string
	end

	def self.create_be_users

		self.init_php_security_bypass

		cmd = ''
		CONFIG['beuser'].each {|k,u|
			cmd += "web/dummy/typo3/cli_dispatch.phpsh lsd_deployt3iu add_beuser -u #{u['username']} -p #{u['password']} -a #{u['admin']} -e #{u['email']};"
		}

		system(cmd)

		self.init_php_security_restore
		
		return cmd
	end

	def self.dt3_helper_extension(action)
		if action == 'install'

			extList = self.getLocalConfExtList()
			extList << 'lsd_deployt3iu'
			extList.uniq
			self.setLocalconfExtList(extList,DT3CONST['TYPO3_LOCALCONF_FILE'])
		elsif action == 'uninstall'
			extList = self.getLocalConfExtList
			extList.delete_if {|x| x == "lsd_deployt3iu"}
			extList.delete('lsd_deployt3iu')
			extList.uniq
			self.setLocalconfExtList(extList,DT3CONST['TYPO3_LOCALCONF_FILE'])
		end
	end

	def self.get_ext_list_from_config_and_extdirs

		extList = []
		extList.concat(CONFIG['typo3']['sysExtList'])

		extDest = File.join(DT3CONST['DUMMYDIR'],"typo3conf","ext") 

		Dir.foreach(File.join("extBundles")) {|rdir| 
			if DT3Div::checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
				Dir.foreach(File.join("extBundles",rdir)) {|sdir| 
					if DT3Div::checkValidDir(sdir) and File.directory?(File.join("extBundles",rdir,sdir))
						extList << sdir
					end
				}
			end
		}

		return extList

	end

	def	self.pre_compile_joined_sql(extList)

		if File.file?(DT3CONST['JOINEDSQL']) 
			FileUtils.rm(DT3CONST['JOINEDSQL'])
		end

		sqlFiles = []
		sqlFiles << File.join(DT3CONST['DUMMYDIR'],"t3lib","stddb","tables.sql") 

		extList.each { | extName |
			extBase = File.join(DT3CONST['DUMMYDIR'],"typo3conf","ext") 
		if CONFIG['typo3']['sysExtList'].include? extName
			extBase = File.join(DT3CONST['DUMMYDIR'],"typo3","sysext") 
		else
			extBase = File.join(DT3CONST['DUMMYDIR'],"typo3conf","ext") 
		end

		extSql = File.join(extBase,extName,"ext_tables.sql") 
		extSqlStatic = File.join(extBase,extName,"ext_tables_static+adt.sql") 

		if File.file?(extSql) 
			sqlFiles << extSql	
		end 
		if File.file?(extSqlStatic) 
			sqlFiles << extSqlStatic	
		end 
		}

		File.open(DT3CONST['JOINEDSQL'],"w"){|f|
			f.puts sqlFiles.map{|s| IO.read(s)} 
		}
		return true
	end
	
	
	def	self.compile_and_import_joined_sql

		self.init_php_security_bypass

		cmd="web/dummy/typo3/cli_dispatch.phpsh lsd_deployt3iu compileSQL -f #{DT3CONST['ROOTDIR']}/joined.sql"
		DT3Logger::log('compile_joined_sql',cmd) 
		system(cmd)
		
		self.init_php_security_restore
		return cmd
	end

	def self.flush_cache()
		DT3Logger::log('flush_cache','removing cache files')
		system("rm -Rf web/dummy/typo3temp/*")
		DT3Logger::log('flush_cache','truncating typo3temp')
		system("rm -Rf web/dummy/typo3conf/temp_CACHED_*")
	end

	def self.init_php_security_bypass

        self.dt3_helper_extension('install')

		#$BE_USER->checkCLIuser();
		#$BE_USER->backendCheckLogin();  // Checking if there's a user logged in

		text = File.read('web/dummy/typo3/init.php')
		text = text.gsub(/^\$BE_USER->checkCLIuser/, "\#$BE_USER->checkCLIuser")
		text = text.gsub(/^\$BE_USER->backendCheckLogin/, "\#$BE_USER->backendCheckLogin")
		File.open('web/dummy/typo3/init.php', "w") {|file| file.puts text}
		self.flush_cache
	end

	def self.init_php_security_restore

		text = File.read('web/dummy/typo3/init.php')
		text = text.gsub(/^\#\$BE_USER->checkCLIuser/, "$BE_USER->checkCLIuser")
			text = text.gsub(/^\#\$BE_USER->backendCheckLogin/, "$BE_USER->backendCheckLogin")
			File.open('web/dummy/typo3/init.php', "w") {|file| file.puts text}

        self.dt3_helper_extension('uninstall')
		self.flush_cache
	end

	def	self.get_db_settings()
		cmd = "php -r \'include \"#{DT3CONST['TYPO3_LOCALCONF_FILE']}\";echo \"$typo_db_username $typo_db_password $typo_db_host $typo_db\";\'"

		dbsettings =%x[ #{cmd} ]
		return dbsettings.split(' ');
	end

	def self.setLocalconfDbSettings(db,user,pass,host='localhost',outfile='web/dummy/typo3conf/localconf.new.php')
		text = File.read(DT3CONST['TYPO3_LOCALCONF_FILE'])
		text = text.gsub(/^\$typo_db_password\ .*/, "$typo_db_password = '"+pass+"'; //set by Deploy TYPO3")
		text = text.gsub(/^\$typo_db\ .*/, "$typo_db = '"+db+"'; //set by Deploy TYPO3")
		text = text.gsub(/^\$typo_db_host\ .*/, "$typo_db_host = '"+host+"'; //set by Deploy TYPO3")
		text = text.gsub(/^\$typo_db_username\ .*/, "$typo_db_username = '"+user+"'; //set by Deploy TYPO3")
		File.open(outfile, "w") {|file| file.puts text}
		return true
	end

	def self.setLocalconfExtList(extList,outfile='web/dummy/typo3conf/localconf.new.php')
		newconf= "$TYPO3_CONF_VARS['EXT']['extList'] = '#{extList.join(',')}'"
		text = File.read(DT3CONST['TYPO3_LOCALCONF_FILE'])
		text = text.gsub(/^\$TYPO3_CONF_VARS\['EXT'\]\['extList'\].*/, newconf+"; //set by Deploy TYPO3")
		File.open(outfile, "w") {|file| file.puts text}
		return true
	end

	def self.getLocalConfExtList(infile='web/dummy/typo3conf/localconf.php')
		cmd = "php -r \'include \"#{infile}\";echo $TYPO3_CONF_VARS[\"EXT\"][\"extList\"];\'"
		extList =%x[ #{cmd} ]
		return extList.split(',');
	end

	def self.add_to_localconf_extlist(extList)

	end

end
