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

require 'rake'  
require 'fileutils'  
require "yaml"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'net/http'

require 'lib/load_config'
require 'lib/init_dt3'
require 'lib/dt3_logger'
require 'lib/dt3_div'
require 'lib/dt3_mysql'
require 'lib/typo3_helper'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

######## SETTING CONSTANTS

CONFIG =LoadConfig::load_config
DT3CONST = InitDT3::load_constants

trackedPaths = CONFIG['trackedPaths'] 

time = Time.new

deploymentName = CONFIG['deploymentName']
$deploymentName = CONFIG['deploymentName']

currentVersion = CONFIG['typo3']['t3version'] 
if currentVersion[0].to_i > 4
	#currentDummy = 'dummy-allversions6plus'
	currentDummy = 'dummy-allversions'
else
	currentDummy = 'dummy-allversions'
	#$localconfFile = 'localconf.php'
end

currentDummydir='dummy'


currentSrcdir= 'typo3_src-'+currentVersion
currentSrcTar = 'typo3_src-'+currentVersion+'.tar.gz'

# All defined webdirectories
webDir = File.join("web") 
extBundlesDir = File.join("extBundles")
rootFilesBundlesDir = File.join("rootFilesBundles")
extSinglesDir = File.join("extBundles","extSingles")
typo3sourceDir = File.join("typo3source")
trackedPathsDir = File.join("trackedPaths")
structDirs = [webDir, extBundlesDir, typo3sourceDir, trackedPathsDir, rootFilesBundlesDir]

upgradingSrc = false

#####################################

task :default => :help

desc 'desc: show main tasks'
task :help do
	print "\n"
	system("rake -T")
	print "\n"
	print "DeployTYPO3 version " + DT3CONST['VERSION']
	print "\n"
	print "\n"
end

desc 'desc: generates a config.yml'
task :conf_init do
	err = Array.new

	if ENV['t3version'].nil?
		err << 'ERROR: you must enter a typo3 version. Enter rake t3:versions to list all available versions'
	end

	if ENV['sitename'].nil?
		err << 'ERROR: no sitename entered'
	end

	if ENV['dbname'].nil?
		err << 'ERROR: no database name entered use dbname=yourdbname'
	end

	if ENV['dbuser'].nil?
		err << 'ERROR: no database user entered use dbuser=user'
	end

	if ENV['dbpass'].nil?
		err << 'ERROR: no database password entered use dbpass=password'
	end

	if ENV['dbhost'].nil?
		err << 'ERROR: no database host entered use dbhost=localhost'
	end

	if !err.empty?  
		err.each do |msg|
			print msg
			print "\n"
		end
		print "\n"
		print "Usage:\n"
		print "rake conf_init sitename=SiteName t3version=4.x.x dbname=database dbuser=username dbpass=password dbhost=hostname"
		print "\n"
		print "\n"
		exit
	end

	print "Creating your initial config.yml\n"
	print "\n"

	text = File.read('config/config.sample.yml')
	text = text.gsub(/deploymentName:\ .*/, "deploymentName: "+ENV['sitename'])
	text = text.gsub(/t3version:\ .*/, "t3version: "+ENV['t3version'])
	text = text.gsub(/dbname:\ .*/, "dbname: "+ENV['dbname'])
	text = text.gsub(/dbuser:\ .*/, "dbuser: "+ENV['dbuser'])
	text = text.gsub(/dbpass:\ .*/, "dbpass: "+ENV['dbpass'])
	text = text.gsub(/dbhost:\ .*/, "dbhost: "+ENV['dbhost'])
	File.open('config/config.yml', "w") {|file| file.puts text}
end

namespace :init do 
	task :localconf_gen do
		#TODO
		#set site name
		#check db is set
		#else ignore

		print "Generating initial localconf.php\n"

		extList = Typo3Helper::get_ext_list_from_config_and_extdirs
		extList.uniq
		Typo3Helper::setLocalconfExtList(extList,DT3CONST['TYPO3_LOCALCONF_FILE'])

		#TODO do not append but replace
		appendCode = """
# deployTYPO3 was here 
# read more about it: https://github.com/Lingewoud/deployTYPO3 
$typo_db_username = '#{CONFIG['typo3']['dbuser']}';   	//  Modified or inserted by deployTYPO3
$typo_db_password = '#{CONFIG['typo3']['dbpass']}';   	// Modified or inserted by deployTYPO3
$typo_db_host = '#{CONFIG['typo3']['dbhost']}';    		//  Modified or inserted by deployTYPO3
$typo_db = '#{CONFIG['typo3']['dbname']}';				//  Modified or inserted by deployTYPO3
"""
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

		Rake::Task["env:flush_cache"].invoke
	end

end

namespace :env do

	desc 'desc: upgrade to newer version'
	task :upgrade_src do

		upgradingSrc = true

		Rake::Task[:getTarballs].invoke
		Rake::Task[:unpackt3].invoke
		Rake::Task["env:relink"].invoke

		print "todo: backup localconf, trackedPaths, install, restore localconf, trackedPaths"
		print "\n"
	end


	desc 'desc: relink extension bundles and extensions'
	task :relink => [:rmExtSymlinks, :linkExtBundles, :linkExtSingles, :linkDummy, :linkTypo3Fix]


	desc 'desc: Create a file web/dummy/typo3conf/ENABLE_INSTALL_TOOL'
	task :touchinst do
		p "creating ENABLE_INSTALL_TOOL"

		system('touch web/'+currentDummydir+'/typo3conf/ENABLE_INSTALL_TOOL')
	end

	desc 'desc: Show main TYPO3 configured settings'
	task :info do
		dbsetarr = Typo3Helper::get_db_settings()

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

	desc 'desc: remove typo3conf cache & temp files'
	task :flush_cache do
		Typo3Helper::flush_cache()
	end

	desc 'desc: purges all typo3 files and extensions. Only leaving this script and your config.yml'
	task :purge do
		print "remove complete typo3 deployment? Enter YES to confirm: " 
		cleanConfirm = STDIN.gets.chomp
		if(cleanConfirm.downcase=='yes')
			system('rm -Rf web trackedPaths typo3source extBundles '+rootFilesBundlesDir)
		end
	end

	desc 'desc: copy complete typo3 environment including deployment scripts and database'
	task :copy do
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
	
		if !err.empty?  
			err.each do |msg|
				print msg
				print "\n"
			end
			print "\n"
			print "Usage:\n"
			print "rake env:copy destpath=[/newpath] destdbname=[database] destdbuser=[username] destdbpass=[password]"
			print "\n"
			print "\n"
			print "Example:\n"
			print "rake env:copy destpath=../typo3copy destdbname=testdb destdbuser=testdbuser destdbpass=testdbpasswordv"
			print "\n"
			print "\n"
			exit
		end

		print "Enter Mysql Root Password"
		print "\n"
		rootdbpass = STDIN.gets.chomp

		dbsetarr = Typo3Helper::get_db_settings()
		sourcedatabase = dbsetarr[3]
		host = dbsetarr[2]

		print "Syncing database"
		print "\n"
		DT3MySQL::copy_database('root',rootdbpass,host,sourcedatabase, ENV['destdbname'])
		print "\n"

		print "Syncing directory\n"
		system("rsync -av ./ "+ ENV['destpath'] +'/')
		print "\n"
		print "Cleaning Cache en Temp directories\n"
		system("rm -Rf "+ ENV['destpath'] +'/web/dummy/typo3conf/temp*')
		system("rm -Rf "+ ENV['destpath'] +'/web/dummy/typo3temp/*')

		Typo3Helper::setLocalconfDbSettings(ENV['destdbname'],ENV['destdbuser'],ENV['destdbpass'], 'localhost', ENV['destpath']+'/'+ DT3CONST['TYPO3_LOCALCONF_FILE'])

	end
end


namespace :ext do
	desc 'desc: download all single extensions defined in config.yml'
	task :singles_get do
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
						srcpath = '/extensions/repository/download/'+key+'/'+hash['version']+'/t3x/'
						destpath = File.join(extSinglesDir,key+'.t3x')

						DT3Div::downloadTo(srcurl,srcpath,destpath)
						cmd = "/usr/bin/php -c lib/expandt3x/php.ini lib/expandt3x/expandt3x.php #{File.join(extSinglesDir, key+'.t3x')}  #{File.join(extSinglesDir,key)}"
						system (cmd)

						FileUtils.rm(File.join(extSinglesDir,key+'.t3x'))
					end
				end
			}
		end
	end

	desc 'desc: purge all extSingles'
	task :singles_purge do
		FileUtils.rm_r extSinglesDir, :force => true  
	end

	desc 'desc: purge all extBundles'
	task :bundles_purge do
		FileUtils.rm_r "extBundles", :force => true  
	end

	desc 'desc: Download all new extension bundles defined in config.yml'
	task :bundles_get do
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
end

namespace :db do
	desc 'desc: active database to sql-file'
	task :backup do

		dbsetarr = Typo3Helper::get_db_settings()

		dbname = dbsetarr[3]
		dbuser = dbsetarr[0]
		dbpass = dbsetarr[1]
		dbhost = dbsetarr[2]

		t = Time.now
		datetime = t.strftime("%Y-%m-%d-time-%H.%M")
		filename = dbsetarr[3] + datetime + ".sql"

		print "Dumping database"
		DT3MySQL::mysqldump_to(dbname,dbuser,dbpass,dbhost,filename)
	end

	desc 'desc: delete all tables'
	task :flush do
		print "Flush tables in DB? Enter YES to confirm: " 
		cleanConfirm = STDIN.gets.chomp
		if(cleanConfirm.downcase=='yes')
			DT3MySQL::flush_tables
		end
	end
	task :flush_force do
		DT3MySQL::flush_tables
	end

	desc 'desc: show all tables'
	task :showtables do
		print("Show tables:\n\n")
		print DT3MySQL::show_tables
		print("\n")
	end

	desc 'desc: copy complete database structure and schema to a new database. This db must already exist'
	task :copy do
		err = Array.new

		if ENV['destdbname'].nil?
			err << 'ERROR: no destination database name entered use destdbname=dbname'
		end

		if !err.empty?  
			err.each do |msg|
				print msg
				print "\n"
			end
			print "\n"
			print "Usage:\n"
			print "rake copy destdbname=[database]"
			print "\n"
			print "\n"
			print "Example:\n"
			print "rake copy destdbname=testdb"
			print "\n"
			print "\n"
			exit
		end

		print "Enter Mysql Root Password"
		print "\n"
		rootdbpass = STDIN.gets.chomp

		dbsetarr = Typo3Helper::get_db_settings()
		sourcedatabase = dbsetarr[3]
		host = dbsetarr[2]

		print "Syncing database"
		print "\n"
		DT3MySQL::copy_database('root',rootdbpass,host,sourcedatabase, ENV['destdbname'])
		print "\n"
	end

	desc 'desc: Install all SQL files'
	task :install do

		extList = Typo3Helper::get_ext_list_from_config_and_extdirs
		Typo3Helper::pre_compile_joined_sql(extList)

		#	flush_cache
		Rake::Task["env:flush_cache"].invoke

		Typo3Helper::compile_and_import_joined_sql

		### CREATE BE USERS
		Typo3Helper::create_be_users

		#	flush_cache
		Rake::Task["env:flush_cache"].invoke

	end
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
	system('ln -sf ../typo3_src-'+currentVersion + ' '+ File.join("web",currentDummydir,'typo3_src'))
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
		if DT3Div::checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			p "In Extension Bundle #{rdir}"

			Dir.foreach(File.join("extBundles",rdir)) {|sdir| 
				if DT3Div::checkValidDir(sdir) and File.directory?(File.join("extBundles",rdir,sdir))
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
end
task :linkExtSinglesOLD do
	print "linking single extensions"
	print "\n"

	if File.directory?(extSinglesDir)

		extDest = File.join('web',currentDummydir,"typo3conf","ext") 

		Dir.foreach(extSinglesDir) {|rdir| 
			if DT3Div::checkValidDir(rdir) and File.directory?(File.join(extSinglesDir,rdir))
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
		if DT3Div::checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
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
		filename = DT3CONST['TYPO3_LOCALCONF_FILE']

		last_line = 0
		file = File.open(filename, 'r+')
		file.each { last_line = file.pos unless file.eof? }
		file.seek(last_line, IO::SEEK_SET)
		file.write(CONFIG['localconf']['initConf'])
		file.write("?>")
		file.close
	end
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

namespace :t3 do

	desc 'desc: do a complete purge and install of the TYPO3 environment'
	#task :install => [:rmdirStruct, :dirStruct, :getTarballs ,:unpackt3, "ext:bundles_get", :linkExtBundles, "ext:singles_get",:linkExtSingles, "init:localconf_gen", :insertInitConf, "env:touchinst", "db:install"]
	
	task :install => [:rmdirStruct, :dirStruct, :getTarballs ,:unpackt3, "ext:bundles_get", "ext:singles_get", :linkExtBundles, :linkExtSingles, "init:localconf_gen", :insertInitConf, "env:touchinst","db:flush_force", "db:install"]

	desc 'desc: show available TYPO3 versions'
	task :versions do
		print Typo3Helper::get_typo3_versions
	end
end

namespace :dev do 
	# read more about version gem @ https://github.com/stouset/version 
	task :version do
		require 'rubygems'
		require 'rake/version_task'
		Rake::VersionTask.new

		Rake::Task["version"].invoke
	end
	task :versionbump do
		require 'rubygems'
		require 'rake/version_task'
		Rake::VersionTask.new

		Rake::Task["version:bump"].invoke
	end
end

namespace :test do 

	task :travis => ["test:unit"]

	task :unit do
		system('rspec spec/test_rakefile_spec.rb')
	end
	task :env do
		system('rspec spec/test_typo3env_spec.rb')
	end
	
	task :all do
		system('rspec spec')
	end
end
