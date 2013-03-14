=begin
 
 Commandline Toolbox for TYPO3 administrator and developers made with Rake. 

 (C) 2013 Lingewoud BV <pim@lingewoud.nl>

Copyright 2013 Pim Snel Copyright 2013 Lingewoud b.v.

This script is part of the TYPO3 project. The TYPO3 project is free software;
you can redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation; either version 2 
of the License, or (at your option) any later version.

The GNU General Public License can be found at 
http://www.gnu.org/copyleft/gpl.html. A copy is found in the textfile GPL.txt
and important notices to the license from the author is found in LICENSE.txt
distributed with these scripts.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details.

This copyright notice MUST APPEAR in all copies of the script!

=end

deployTypo3Version = "1.5"

require 'rake'  
require 'fileutils'  
require "yaml"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'net/http'

if File.file?("config/config.yml")
	CONFIG = YAML::load(File.open("config/config.yml"))
else
	print "Using sample configuration, please replace with your own"
	print "\n"
	CONFIG = YAML::load(File.open("config/config.sample.yml"))
end

trackedPaths = CONFIG['trackedPaths'] 

time = Time.new

deploymentName = CONFIG['deploymentName']

currentVersion = CONFIG['typo3']['version'] 
if currentVersion[0].to_i > 4
	currentDummy = 'dummy-allversions6plus'
	currentDummy = 'dummy-allversions'
	$localconfFile = 'LocalConfiguration.php'
	$localconfFile = 'localconf.php'
else
	currentDummy = 'dummy-allversions'
	$localconfFile = 'localconf.php'
end

currentDummydir='dummy'

currentSrcdir= 'typo3_src-'+currentVersion
currentSrcTar = 'typo3_src-'+currentVersion+'.tar.gz'

# All defined webdirectories
webDir = File.join("web") 
extBundlesDir = File.join("extBundles")
rootFilesBundlesDir = File.join("rootFilesBundles")
extSinglesDir = File.join("extSingles")
typo3sourceDir = File.join("typo3source")
trackedPathsDir = File.join("trackedPaths")
structDirs = [webDir, extBundlesDir, typo3sourceDir, trackedPathsDir, rootFilesBundlesDir]

upgradingSrc = false

$extList = []

task :default => :help

desc 'desc: do a complete purge and install'
task :t3_install => [:rmdirStruct, :dirStruct, :conf_init, :getTarballs ,:unpackt3, :ext_bundles_get, :linkExtBundles, :ext_singles_get,:linkExtSingles, :insertInitConf, :env_touchinst]

task :conf_init do
	p "ARGS"
	p "DO"
end

desc 'desc: upgrade to newer version'
task :env_upgrade_src do

	upgradingSrc = true

	Rake::Task[:getTarballs].invoke
   	Rake::Task[:unpackt3].invoke
   	Rake::Task[:env_relink].invoke

	print "todo: backup localconf, trackedPaths, install, restore localconf, trackedPaths"
	print "\n"
end

desc 'desc: show main tasks'
task :help do
	print "DeployTYPO3 version " + deployTypo3Version
	print "\n"
	system("rake -T")
end

desc 'desc: relink extension bundles and extensions'
task :env_relink => [:rmExtSymlinks, :linkExtBundles, :linkExtSingles, :linkDummy, :linkTypo3Fix]

desc 'desc: download all single extensions defined in config.yml'
task :ext_singles_get do
	if CONFIG['extSingles']
		print "Downloading single extensions\n"

		if not File.directory?(File.join(extSinglesDir))
			FileUtils.mkdir extSinglesDir
		end

		CONFIG['extSingles'].each {|key,hash|

			if not File.directory?(File.join(extSinglesDir,key))
				if(hash['type']=='git')
					system("git clone " + hash['uri'] + " "+ File.join(extSinglesDir,key))
				end
				if(hash['type']=='ter')
					
					srcurl ='typo3.org'
					p hash
					srcpath = '/extensions/repository/download/'+key+'/'+hash['version']+'/t3x/'
					destpath = File.join(extSinglesDir,key+'.t3x')

					downloadTo(srcurl,srcpath,destpath)
					cmd = '/usr/bin/php -c lib/expandt3x/php.ini lib/expandt3x/expandt3x.php extSingles/'+key+'.t3x '+ ' extSingles/'+key
					system (cmd)

					FileUtils.rm('extSingles/'+key+'.t3x')
				end
			end

		}
	end
end

desc 'desc: purge all extSingles'
task :ext_singles_purge do
	FileUtils.rm_r extSinglesDir, :force => true  
end

desc 'desc: purge all extBundles'
task :ext_bundles_purge do
	FileUtils.rm_r "extBundles", :force => true  
end

desc 'desc: Download all new extension bundles defined in config.yml'
task :ext_bundles_get do
	print "Downloading all new extension bundles\n"

	if not File.directory?(File.join("extBundles"))
		FileUtils.mkdir "extBundles"
	end

	if(CONFIG['extBundles']) 
		CONFIG['extBundles'].each {|key,hash|
			print key
			if not File.directory?(File.join("extBundles",key))
				if(hash['type']=='svn')
					print("svn co " + hash['uri'] + " extBundles/"+ key)
				end
				if(hash['type']=='git')
					system("git clone " + hash['uri'] + " extBundles/"+ key)
				end
			end
		}
	end
end

desc 'desc: Create a file web/dummy/typo3conf/ENABLE_INSTALL_TOOL'
task :env_touchinst do
	p "creating ENABLE_INSTALL_TOOL"
	
	system('touch web/'+currentDummydir+'/typo3conf/ENABLE_INSTALL_TOOL')
end

desc 'desc: Show main TYPO3 configured settings'
task :env_info do
	dbsetarr = getDbSettings()

	print "\n"
	print "TYPO3 Version: "+currentVersion 
	print "\n"
	print "Docroot directory: "+ FileUtils.pwd + '/web/' + currentDummydir
	print "\n"
	print 'Database: ' + dbsetarr[3]
	print "\n"
	print 'Host: ' + dbsetarr[2]
	print "\n"
	print 'User: ' + dbsetarr[0]
	print "\n"
	print 'Password: ' + dbsetarr[1]
	print "\n"
	print "\n"
end

desc 'desc: active database to sql-file'
task :db_backup do
	dbsetarr = getDbSettings()

	t = Time.now
	datetime = t.strftime("%Y-%m-%d-time-%H.%M")   #=> "Printed on 04/09/2003"

	print "Dumping database"
	print "\n"
	system("mysqldump " +  dbsetarr[3]  + " -u"+ dbsetarr[0] + " -p"+ dbsetarr[1] +" > "+ dbsetarr[3] + datetime + ".sql")
	print "\n"

end

desc 'desc: remove typo3conf cache & temp files'
task :env_flush_cache do
	p "removing cache files"
	system("rm -Rf web/dummy/typo3temp/*")
	p "truncating typo3temp"
	system("rm web/dummy/typo3conf/temp_CACHED_*")
end

#desc 'copy all trackedPaths to trackedPathsDir for storage in SCM'
task :trackDown do
	trackedPaths.each {|path|
		File.makedirs(File.join('trackedPaths',File.dirname(path)))
		FileUtils.cp_r(path, File.join('trackedPaths',File.dirname(path)))
		p path
	}
end

#desc 'copy all trackedPaths from trackedPathsDir to their location'
#task :trackUp do
#	trackedPaths.each {|path|
#		FileUtils.cp_r(File.join('trackedPaths',File.dirname(path)),path)
#		p path
#	}
#end

# ----------- SUB TASKS ---------- #

task :getTarballs do
	sfmirror = CONFIG['typo3']['sfmirror']
	sourceUrl = sfmirror+'.dl.sourceforge.net'
	downloadLink='/project/typo3/TYPO3%20Source%20and%20Dummy/TYPO3%20'+currentVersion+'/typo3_src-'+currentVersion+'.tar.gz'

	Net::HTTP.start(sourceUrl) { |http2|
		resp2 = http2.get(downloadLink)
			open("typo3source/"+currentSrcTar, "w+") { |file2|
				file2.write(resp2.body)
			}
	}

end

task :unpackt3 do

	if File.directory?(File.join('web', currentSrcdir))
		FileUtils.rm_r( File.join('web', currentSrcdir) )
	end

	if File.directory?(File.join('web', currentDummydir))
		if not upgradingSrc
			system('mv web/'+currentDummydir + " web/"+currentDummydir + "-bak-"+time.year.to_s+'-'+time.month.to_s+'-'+time.day.to_s+'-'+time.hour.to_s+'.'+time.min.to_s)
		end
	end

	if not File.directory?(File.join('web', currentDummydir))
		system('tar xzf '+currentDummy+'.tar.gz -C web/')
		system('mv web/'+currentDummy+' web/'+currentDummydir)
	end

	system('tar xzf typo3source/typo3_src-'+currentVersion+'.tar.gz -C web/')
#	system('rm '+ File.join("web",currentDummydir,'typo3_src'))
#	p 'ln -sf '+ File.join("web",currentDummydir,'typo3_src') +' ../typo3_src-'+currentVersion
	system('ln -sf ../typo3_src-'+currentVersion + ' '+ File.join("web",currentDummydir,'typo3_src'))
#	system('mv web/'+currentDummydir + "/ web/"+currentDummydir + "-bak-"+time.year.to_s+'-'+time.month.to_s+'-'+time.day.to_s+'-'+time.hour.to_s+'.'+time.min.to_s)

	#File.symlink( "web/"+currentDummydir+"/typo3", "../typo3") 
	#system('chmod -Rf 777 web/' + currentDummydir)
end

desc 'desc: purges all typo3 files and extensions. Only leaving this script and your config.yml'
task :env_purge do
	print "remove complete typo3 deployment? Enter YES to confirm: " 
	cleanConfirm = STDIN.gets.chomp
	if(cleanConfirm.downcase=='yes')
		system('rm -Rf web trackedPaths typo3source extBundles '+rootFilesBundlesDir)
	end
end

desc 'desc: delete all tables'
task :db_flush do
	print "Flush tables in DB? Enter YES to confirm: " 
	cleanConfirm = STDIN.gets.chomp
	if(cleanConfirm.downcase=='yes')
		cmd = "mysql -u#{CONFIG['typo3']['dbuser']} -h#{CONFIG['typo3']['dbhost']} -p#{CONFIG['typo3']['dbpass']} #{CONFIG['typo3']['dbname']} -e \"show tables\" | grep -v Tables_in | grep -v \"+\" | gawk '{print \"drop table \" $1 \";\"}' | mysql -u#{CONFIG['typo3']['dbuser']} -h#{CONFIG['typo3']['dbhost']} -p#{CONFIG['typo3']['dbpass']} #{CONFIG['typo3']['dbname']}"
		system(cmd)
	end
end

desc 'desc: show all tables'
task :db_showtables do
	print "Show tables:" 
	cmd = "mysql -u#{CONFIG['typo3']['dbuser']} -h#{CONFIG['typo3']['dbhost']} -p#{CONFIG['typo3']['dbpass']} #{CONFIG['typo3']['dbname']} -e \"show tables\""
	system(cmd)
end

task :linkTypo3Fix do
	print "symlink typo3 fix"
	print "\n"
	system('ln -sf '+ File.join("web",currentDummydir,'typo3') +' typo3')
end

task :rmExtSymlinks do
	system('rm -Rfv `find web/dummy/typo3conf/ext -type l`')
end

task :linkExtBundles do
	print "linking extension bundles"
	print "\n"

	extDest = File.join('web',currentDummydir,"typo3conf","ext") 

	   Dir.foreach(File.join("extBundles")) {|rdir| 
		   if checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			   p "In Extension Bundle #{rdir}"

			   Dir.foreach(File.join("extBundles",rdir)) {|sdir| 
				   if checkValidDir(sdir) and File.directory?(File.join("extBundles",rdir,sdir))
					   source = File.join("..","..","..","..","extBundles",rdir,sdir) 

					   system("ln -sf " + source + " " +extDest)
					   p "ln -sf " + source + " " +extDest
					   
				   end
			   }
		   end
	   }

	   #todo add removing broken symlinks with command below
	   #for i in `find ./ -type l`; do [ -e $i ] || echo $i is broken; done
end

task :linkDummy do
	print "linking inside dummy"
	print "\n"

	if File.directory?(File.join("web",currentDummydir))
		system('rm '+ File.join("web",currentDummydir,'typo3_src'))
		system('ln -s '+ File.join("..",currentSrcdir) + ' ' + File.join("web",currentDummydir,'typo3_src'))
	end
end

task :linkExtSingles do
	print "linking single extensions"
	print "\n"

	if File.directory?(extSinglesDir)

		extDest = File.join('web',currentDummydir,"typo3conf","ext") 

		Dir.foreach(extSinglesDir) {|rdir| 
			if checkValidDir(rdir) and File.directory?(File.join(extSinglesDir,rdir))
				print "In Extension #{rdir}"
				print "\n"
				source = File.join("..","..","..","..",extSinglesDir,rdir) 

				system("ln -sf " + source + " " +extDest)
				print "ln -sf " + source + " " +extDest
				print "\n"

			end
		}
	end
end

#desc 'svnStatusExtBundles: per extBundle check the svn status'
task :svnStatusExtBundles do
	print "checking de subversion status of extension bundles"
	print "\n"

	Dir.foreach(File.join("extBundles")) {|rdir| 
		if checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			p "In Extension Bundle #{rdir}"

			system("svn status " + File.join("extBundles",rdir))
		end
	}
end

#desc 'rmdirStruct: remove all but the scriptfiles files'
task :rmdirStruct do
	structDirs.each {|dirx|
		FileUtils.rm_r dirx, :force => true  
	}
end

#desc 'dirstruct: make or update directory structure'
task :dirStruct do
	structDirs.each {|dirx|
		if not File.directory?(dirx)
			FileUtils.mkdir(dirx)
		end
	}
end

task :insertInitConf do
	if(CONFIG.has_key?('localconf') && CONFIG['localconf'].has_key?('initConf'))
		filename = "web/dummy/typo3conf/"+$localconfFile

		last_line = 0
		file = File.open(filename, 'r+')
		file.each { last_line = file.pos unless file.eof? }
		file.seek(last_line, IO::SEEK_SET)
		file.write(CONFIG['localconf']['initConf'])
		file.write("?>")
		file.close
	end
end

task :generateConf do
#compile extList, all sysExt, plus all extBundles/ext's, plus all extSingles  
	#sysextlist + contents of extBundles and extSingles
compileExtList
p $extList
end

desc 'desc: copy complete typo3 environment including deployment scripts and database'
task :env_copy do
	err = Array.new

	if ENV['destpath'].nil?
		err << 'ERROR: no destination path entered use dest=/newpath'
	end

	if ENV['destdbname'].nil?
		err << 'ERROR: no destination database name entered use destdbname=dbname'
	end

	if ENV['destdbuser'].nil?
		err << 'ERROR: no destination database username entered use destdbuser=user'
	end

	if ENV['destdbpass'].nil?
		err << 'ERROR: no destination database password entered use destdbpass=password'
	end

#	if ENV['destdbhost'].nil?
#		dbhost=
#		err << 'ERROR: no destination database host entered use destdbhost=hostaddress'
#	end

	if !err.empty?  
		err.each do |msg|
			print msg
			print "\n"
		end
		print "\n"
		print "Usage:\n"
		print "rake env_copy destpath=[/newpath] destdbname=[database] destdbuser=[username] destdbpass=[password]"
		print "\n"
		print "\n"
		print "Example:\n"
		print "rake env_copy destpath=../typo3copy destdbname=testdb destdbuser=testdbuser destdbpass=testdbpasswordv"
		print "\n"
		print "\n"
		exit
	end

	print "Enter Mysql Root Password"
	print "\n"
	    rootdbpass = STDIN.gets.chomp

	dbsetarr = getDbSettings()
	sourcedatabase = dbsetarr[3]

	#print "Current dir"
	#system('pwd')

	print "Syncing database"
	print "\n"
	system("mysqldump " + sourcedatabase + " -uroot -p"+ rootdbpass +" | mysql -uroot -p"+ rootdbpass +" "+ ENV['destdbname'])
	print "\n"

	print "Syncing directory\n"
	system("rsync -av ./ "+ ENV['destpath'] +'/')
	print "\n"
	print "Cleaning Cache en Temp directories\n"
	system("rm -Rf "+ ENV['destpath'] +'/web/dummy/typo3conf/temp*')
	system("rm -Rf "+ ENV['destpath'] +'/web/dummy/typo3temp/*')

	setLocalconfDbSettings(ENV['destdbname'],ENV['destdbuser'],ENV['destdbpass'], 'localhost', ENV['destpath']+'/web/dummy/typo3conf/'+$localconfFile)
end

desc 'desc: copy complete database structure and schema to a new database. This db must already exist'
task :db_copy do
	err = Array.new

	if ENV['destdbname'].nil?
		err << 'ERROR: no destination database name entered use destdbname=dbname'
	end

#	if ENV['destdbuser'].nil?
#		err << 'ERROR: no destination database username entered use destdbuser=user'
#	end

#	if ENV['destdbpass'].nil?
#		err << 'ERROR: no destination database password entered use destdbpass=password'
#	end

#	if ENV['destdbhost'].nil?
#		dbhost=
#		err << 'ERROR: no destination database host entered use destdbhost=hostaddress'
#	end

	if !err.empty?  
		err.each do |msg|
			print msg
			print "\n"
		end
		print "\n"
		print "Usage:\n"
		print "rake db_copy destdbname=[database]"
		print "\n"
		print "\n"
		print "Example:\n"
		print "rake db_copy destdbname=testdb"
		print "\n"
		print "\n"
		exit
	end

	print "Enter Mysql Root Password"
	print "\n"
    rootdbpass = STDIN.gets.chomp

	dbsetarr = getDbSettings()
	sourcedatabase = dbsetarr[3]

	#print "Current dir"
	#system('pwd')

	print "Syncing database"
	print "\n"
	system("mysqldump " + sourcedatabase + " -uroot -p"+ rootdbpass +" | mysql -uroot -p"+ rootdbpass +" "+ ENV['destdbname'])
	print "\n"
end

task :setdatabasetest do
	setLocalconfDbSettings('dbname','user','password','host')
end

desc 'desc: make link a dir lower indicating this is live'
task :env_livelink do

	if(!deploymentName)
		deploymentName = 'noName-please-configure'
	end

	rmsymlink('../TYPO3Live-'+deploymentName)

	print "symlink this as live environment"
	print "\n"
	system('ln -sf ' + Dir.pwd + ' ' + File.join("..",'TYPO3Live-'+deploymentName))
end

desc 'desc: append configured php code to configured files, usefull for overriding modules configurations'
task :patch_append_php do

	CONFIG['appendPHPToFile'].each {|key,valarr|
		print 'Append task for: '+key+ "\n"
		filename = 'web/'+currentDummydir+'/'+valarr['file']
		appendCode = valarr['appendPHPCode']
		
		if File.file?(filename) 
			last_line = 0
			file = File.open(filename, 'r+')
			file.each { last_line = file.pos unless file.eof? }
			file.seek(last_line, IO::SEEK_SET)
			file.write(appendCode)
			file.write("?>")
			file.close
		else
		print "file does not exist: "+	filename + "\n"
		end
	}

end

#desc 'defaultSiteRootFiles: copy files into site root'
task :defaultSiteRootFiles do

	FileUtils.rm_r rootFilesBundlesDir, :force => true  
	FileUtils.mkdir rootFilesBundlesDir

	CONFIG['defaultSiteRootFiles'].each {|key,val|
		p "checking out root files bundle: "+key
		system("svn co " + val + " "+ rootFilesBundlesDir+"/"+ key)
		p "syncing root files bundle: "+key
		system("rsync --exclude=.git --exclude=.svn -av "+ rootFilesBundlesDir + "/"+ key +'/ web/'+currentDummydir +'/' )
	}

	print "\n"
end

desc 'desc: echo cron confguration'
task :env_cron do

	livePath = File.expand_path(File.join(Dir.pwd,"..",'TYPO3Live-'+deploymentName))

	print "CRON SCHEDULAR CONFIGURATION"
	print "\n"
	print '*/5 * * * * root '+livePath+'/web/dummy/typo3/cli_dispatch.phpsh scheduler'
	print "\n"
	print "echo '*/5 * * * * root "+livePath+"/web/dummy/typo3/cli_dispatch.phpsh scheduler' > /etc/cron.d/typo3-"+deploymentName
	print "\n"

end

desc 'desc: show available TYPO3 versions'
task :t3_versions do

	source = "http://sourceforge.net/api/file/index/project-id/20391/mtime/desc/rss"
	content = "" # raw content of rss feed will be loaded here
	open(source) do |s| content = s.read end
	rss = RSS::Parser.parse(content, false)

	print "RSS title: ", rss.channel.title, "\n"
	print "RSS link: ", rss.channel.link, "\n"
	print "RSS description: ", rss.channel.description, "\n"
	print "RSS publication date: ", rss.channel.date, "\n"

	puts "Item values"
	_version_arr= []
	rss.items.each { |item|
		if item.title[0,24] =='/TYPO3 Source and Dummy/' 
			_item = item.title[24,1000].split(/\//)
			_version_arr << _item[0]
		end
	}
	version_arr = _version_arr.uniq.sort
	version_arr.each { |v|
			print "version: ", v, "\n"
	}
end

desc 'desc: Install all SQL files'
task :db_install do

	filename='joined.sql'
	if File.file?(filename) 
		FileUtils.rm(filename)
	end

	$sqlFiles = []
	$sqlFiles << File.join('web',currentDummydir,"t3lib","stddb","tables.sql") 

	compileExtList
	$extList.each { | extName |
	    extBase = File.join('web',currentDummydir,"typo3conf","ext") 
		if CONFIG['typo3']['sysExtList'].include? extName
			extBase = File.join('web',currentDummydir,"typo3","sysext") 
		else
			extBase = File.join('web',currentDummydir,"typo3conf","ext") 
		end

		extSql = File.join(extBase,extName,"ext_tables.sql") 
		extSqlStatic = File.join(extBase,extName,"ext_tables_static+adt.sql") 
		if File.file?(extSql) 
			$sqlFiles << extSql	
		end 
		if File.file?(extSqlStatic) 
			$sqlFiles << extSqlStatic	
		end 
	}

	File.open(filename,"w"){|f|
		  f.puts $sqlFiles.map{|s| IO.read(s)} 
	}

	cmd="web/dummy/typo3/cli_dispatch.phpsh lsd_deployt3iu compileSQL -f #{File.dirname(__FILE__)}/joined.sql"
	system(cmd)

end

def getDbSettings()
	cmd = "php -r \'include \"web/dummy/typo3conf/"+$localconfFile+"\";echo \"$typo_db_username $typo_db_password $typo_db_host $typo_db\";\'"
	dbsettings =%x[ #{cmd} ]
	dbsettings.split(' ');
end

def setLocalconfDbSettings(db,user,pass,host='localhost',outfile='web/dummy/typo3conf/localconf.new.php')
	
	text = File.read('web/dummy/typo3conf/'+$localconfFile)
	text = text.gsub(/^\$typo_db_password\ .*/, "$typo_db_password = '"+pass+"'; //set by Deploy TYPO3")
	text = text.gsub(/^\$typo_db\ .*/, "$typo_db = '"+db+"'; //set by Deploy TYPO3")
	text = text.gsub(/^\$typo_db_host\ .*/, "$typo_db_host = '"+host+"'; //set by Deploy TYPO3")
	text = text.gsub(/^\$typo_db_username\ .*/, "$typo_db_username = '"+user+"'; //set by Deploy TYPO3")
	File.open(outfile, "w") {|file| file.puts text}
end

def rmsymlink(symlink)
	if File.symlink?( symlink )
		FileUtils.rm_r( symlink )
	end
end

def checkValidDir(dir)
	if dir!= '..' and dir != '.' and dir!= '.svn' and dir!= '.git'
		return true
	else
		return false
	end
end

def downloadTo(src_url,src_path,dest_filepath)
	Net::HTTP.start(src_url) { |http2|
		resp2 = http2.get(src_path)
			open(dest_filepath, "w+") { |file2|
				file2.write(resp2.body)
			}
	}
end

def compileExtList

	$extList.concat(CONFIG['typo3']['sysExtList'])

	extDest = File.join('web','dummy',"typo3conf","ext") 

	Dir.foreach(File.join("extBundles")) {|rdir| 
		if checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			Dir.foreach(File.join("extBundles",rdir)) {|sdir| 
				if checkValidDir(sdir) and File.directory?(File.join("extBundles",rdir,sdir))
					$extList << sdir
				end
			}
		end
	}
	Dir.foreach(File.join("extSingles")) {|rdir| 
		if checkValidDir(rdir) and File.directory?(File.join("extSingles",rdir))
			$extList << rdir
		end
	}
end


