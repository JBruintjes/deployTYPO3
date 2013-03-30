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

			appendCode = "\n$TYPO3_CONF_VARS['EXT']['extList'] .= ',lsd_deployt3iu,extbase';\n"

			if File.file?(DT3CONST['TYPO3_LOCALCONF_FILE']) 
				last_line = 0
				file = File.open(DT3CONST['TYPO3_LOCALCONF_FILE'], 'r+')
				file.each { last_line = file.pos unless file.eof? }
				file.seek(last_line, IO::SEEK_SET)
				file.write(appendCode)
				file.write("?>")
				file.close
			else
				print "file does not exist: "+	DT3CONST['TYPO3_LOCALCONF_FILE'] + "\n"
			end

		elsif action == 'uninstall'
			text = File.read(DT3CONST['TYPO3_LOCALCONF_FILE'])
			text = text.gsub(/^\$TYPO3_CONF_VARS\['EXT'\]\['extList'\]\ \.=\ ',lsd_deployt3iu,extbase';/, "")
			File.open(DT3CONST['TYPO3_LOCALCONF_FILE'], "w") {|file| file.puts text}
		end
	end

	def	self.compile_joined_sql

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
end



