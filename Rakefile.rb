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

require 'rubygems'
require 'nokogiri'
require "base64"
require 'php_serialize'

require 'lib/load_config'
require 'lib/init_dt3'
require 'lib/dt3_logger'
require 'lib/dt3_div'
require 'lib/dt3_mysql'
require 'lib/typo3_helper'
require 'lib/expandt3x.rb'
require 'lib/helpinfo.rb'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

######## SETTING CONSTANTS

CONFIG =LoadConfig::load_config
DT3CONST = InitDT3::load_constants

trackedPaths = CONFIG['trackedPaths'] 
rootFilesBundlesDir = File.join("rootFilesBundles")

time = Time.new

#####################################

task :default => :help

desc 'desc: show main tasks'
task :help do
	HelpInfo::print_help
end

desc 'desc: show all including dev and sub tasks'
task :help_exp do
	HelpInfo::print_help(true)
end

namespace :init do 
	desc 'desc: generates a config.yml'
	task :conf do
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
end

namespace :env do
	desc 'desc: make link a dir lower indicating this is live'
	task :livelink do

		deploymentName = ''

		if(!CONFIG['deploymentName'])
			deploymentName = 'noName-please-configure'
		else
			deploymentName = CONFIG['deploymentName']
		end
		

		rmsymlink('../TYPO3Live-'+deploymentName)

		print "symlink this as live environment"
		print "\n"
		system('ln -sf ' + Dir.pwd + ' ' + File.join("..",'TYPO3Live-'+deploymentName))
	end

	desc 'desc: echo cron confguration'
	task :cron do

		livePath = File.expand_path(File.join(Dir.pwd,"..",'TYPO3Live-'+CONFIG['deploymentName']))

		print "CRON SCHEDULAR CONFIGURATION"
		print "\n"
		print '*/5 * * * * root '+livePath+'/web/dummy/typo3/cli_dispatch.phpsh scheduler'
		print "\n"
		print "echo '*/5 * * * * root "+livePath+"/web/dummy/typo3/cli_dispatch.phpsh scheduler' > /etc/cron.d/typo3-"+CONFIG['deploymentName']
		print "\n"
	end

	desc 'desc: upgrade to newer version'
	task :upgrade_src do

		$upgradingSrc = true

		Rake::Task['sub:getTarballs'].invoke
		Rake::Task['sub:unpackt3'].invoke
		Rake::Task["env:relink"].invoke

		print "todo: backup localconf, trackedPaths, install, restore localconf, trackedPaths"
		print "\n"
	end

	desc 'desc: relink extension bundles and extensions'
	task :relink do 
		Rake::Task['sub:rmExtSymlinks'].invoke
		Rake::Task['sub:linkExtBundles'].invoke
		Rake::Task["env:linkDummy"].invoke
		Rake::Task["env:linkTypo3Fix"].invoke
	end

	desc 'desc: Create a file web/dummy/typo3conf/ENABLE_INSTALL_TOOL'
	task :touchinst do
		p "creating ENABLE_INSTALL_TOOL"
		system('touch web/'+DT3CONST['RELDIRS']['CURRENTDUMMY']+'/typo3conf/ENABLE_INSTALL_TOOL')
	end

	desc 'desc: Show main TYPO3 configured settings'
	task :info do
		dbsetarr = Typo3Helper::get_db_settings()

		print "\n"
		print "TYPO3 Version: "+CONFIG['typo3']['t3version'] 
		print "\n"
		print "Docroot directory: "+ FileUtils.pwd + '/web/' + DT3CONST['RELDIRS']['CURRENTDUMMY']
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
			Rake::Task['sub:rmdirStruct'].invoke
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

			if not File.directory?(File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR']))
				FileUtils.mkdir DT3CONST['RELDIRS']['EXTSINGLESDIR']
			end

			CONFIG['extSingles'].each {|key,hash|
				if not File.directory?(File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key))
					if(hash['type']=='git')
						system("git clone " + hash['uri'] + " "+ File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key))
					end
					if(hash['type']=='ter')

						srcurl ='typo3.org'
						srcpath = '/extensions/repository/download/'+key+'/'+hash['version']+'/t3x/'
						destpath = File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key+'.t3x')

						DT3Div::downloadTo(srcurl,srcpath,destpath)

						cmd = "/usr/bin/php -c lib/expandt3x/php.ini lib/expandt3x/expandt3x.php #{File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'], key+'.t3x')}  #{File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key)}"
						system (cmd)

						FileUtils.rm(File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key+'.t3x'))
					end
				end
			}
		end
	end

	desc 'desc: purge all extSingles'
	task :singles_purge do
		if CONFIG['extSingles']
			print "Removing single extensions\n"

			CONFIG['extSingles'].each {|key,hash|
				FileUtils.rm_r File.join(DT3CONST['RELDIRS']['EXTSINGLESDIR'],key), :force => true  
			}
		end
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

	desc 'desc: show all tables'
	task :tables do
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

namespace :t3org do
	desc 'desc: show last TYPO3 versions'
	task :lastversions do
		versions= Typo3Helper::get_typo3_versions
		print Typo3Helper::last_minor_version(versions,'3.3') +"\n"
		print Typo3Helper::last_minor_version(versions,'3.4') +"\n"
		print Typo3Helper::last_minor_version(versions,'3.7') +"\n"
		print Typo3Helper::last_minor_version(versions,'3.8') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.1') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.2') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.3') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.4') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.5') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.6') +"\n"
		print Typo3Helper::last_minor_version(versions,'4.7') +"\n"
		print Typo3Helper::last_minor_version(versions,'6.0') +"\n"
		#print Typo3Helper::last_minor_version(versions,'6.1') +"\n"
	end

	desc 'desc: show available TYPO3 versions'
	task :versions do
		print Typo3Helper::get_typo3_versions
	end
end

namespace :inst do

	desc 'desc: purge and install the complete configured TYPO3 environment'
	task :all do
		Rake::Task['sub:rmdirStruct'].invoke
		Rake::Task['sub:dirStruct'].invoke
		Rake::Task['sub:getTarballs'].invoke
		Rake::Task['sub:unpackt3'].invoke
		Rake::Task['ext:bundles_get'].invoke
		Rake::Task['ext:singles_get'].invoke
		Rake::Task['sub:linkExtBundles'].invoke
		Rake::Task['sub:localconf_gen'].invoke
		Rake::Task['sub:insertInitConf'].invoke
		Rake::Task['env:touchinst'].invoke
		DT3MySQL::flush_tables
		Rake::Task['db:install'].invoke
		Rake::Task['sub:linkTypo3Fix'].invoke
	end

	desc 'desc: purge and download the complete environment but do not setup the localconf & db. Do this manually.' 
	task :man do
		Rake::Task['sub:rmdirStruct'].invoke
		Rake::Task['sub:dirStruct'].invoke
		Rake::Task['sub:getTarballs'].invoke
		Rake::Task['sub:unpackt3'].invoke
		Rake::Task['ext:bundles_get'].invoke
		Rake::Task['ext:singles_get'].invoke
		Rake::Task['sub:linkExtBundles'].invoke
		Rake::Task['sub:localconf_gen'].invoke
		Rake::Task['sub:insertInitConf'].invoke
		Rake::Task['env:touchinst'].invoke
		DT3MySQL::flush_tables
		Rake::Task['sub:linkTypo3Fix'].invoke
	end

	desc 'desc: purge and install the configured TYPO3 environment without external extensions'
	task :min do
		Rake::Task['sub:rmdirStruct'].invoke
		Rake::Task['sub:dirStruct'].invoke
		Rake::Task['sub:getTarballs'].invoke
		Rake::Task['sub:unpackt3'].invoke
		Rake::Task['sub:localconf_gen'].invoke
		Rake::Task['sub:insertInitConf'].invoke
		Rake::Task['env:touchinst'].invoke
		DT3MySQL::flush_tables
		Rake::Task['db:install'].invoke
		Rake::Task['sub:linkTypo3Fix'].invoke
	end
end

namespace :sub do

	desc 'desc: genetate an initial localconf'
	task :localconf_gen do
		print "Generating initial localconf.php\n"
		Typo3Helper::create_init_localconf
		Rake::Task["env:flush_cache"].invoke
	end

	desc 'desc: add an extra symlink to make sure the backpath of some exts work'
	task :linkTypo3Fix do
		print "symlink typo3 fix"
		print "\n"
		system('ln -sf '+ File.join("web",DT3CONST['RELDIRS']['CURRENTDUMMY'],'typo3') +' typo3')
	end

	desc 'desc: remove all symlinks from the dir: .../typo3conf/ext'
	task :rmExtSymlinks do
		system('rm -Rfv `find web/dummy/typo3conf/ext -type l`')
		#todo add removing broken symlinks with command below
		#for i in `find ./ -type l`; do [ -e $i ] || echo $i is broken; done
	end

	desc 'desc: link all extension in extBundles dir to .../typo3conf/ext'
	task :linkExtBundles do
		print "linking extension bundles"
		print "\n"

		extDest = File.join('web',DT3CONST['RELDIRS']['CURRENTDUMMY'],"typo3conf","ext") 

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

	end

	desc 'desc: add initial config to localconf'
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

	desc 'desc: downloaded dummy and source tarballs'
	task :getTarballs do
		sfmirror = CONFIG['typo3']['sfmirror']
		sourceUrl = sfmirror+'.dl.sourceforge.net'
		downloadLink='/project/typo3/TYPO3%20Source%20and%20Dummy/TYPO3%20'+CONFIG['typo3']['t3version']+'/typo3_src-'+CONFIG['typo3']['t3version']+'.tar.gz'

		Net::HTTP.start(sourceUrl) { |http2|
			resp2 = http2.get(downloadLink)
			open("typo3source/"+DT3CONST['CURRENTSRCTAR'], "w+") { |file2|
				file2.write(resp2.body)
			}
		}

	end

	desc 'desc: unpack downloaded dummy and source tarballs'
	task :unpackt3 do
		if File.directory?(File.join('web', DT3CONST['RELDIRS']['CURRENTSRC']))
			FileUtils.rm_r( File.join('web', DT3CONST['RELDIRS']['CURRENTSRC']) )
		end

		if File.directory?(File.join('web', DT3CONST['RELDIRS']['CURRENTDUMMY']))
			if not $upgradingSrc
				system('mv web/'+DT3CONST['RELDIRS']['CURRENTDUMMY'] + " web/"+DT3CONST['RELDIRS']['CURRENTDUMMY'] + "-bak-"+time.year.to_s+'-'+time.month.to_s+'-'+time.day.to_s+'-'+time.hour.to_s+'.'+time.min.to_s)
			end
		end

		if not File.directory?(File.join('web', DT3CONST['RELDIRS']['CURRENTDUMMY']))
			system('tar xzf '+DT3CONST['CURRENTDUMMY']+'.tar.gz -C web/')
			system('mv web/'+DT3CONST['CURRENTDUMMY']+' web/'+DT3CONST['RELDIRS']['CURRENTDUMMY'])
		end

		system('tar xzf typo3source/typo3_src-'+CONFIG['typo3']['t3version']+'.tar.gz -C web/')
		system('ln -sf ../typo3_src-'+CONFIG['typo3']['t3version'] + ' '+ File.join("web",DT3CONST['RELDIRS']['CURRENTDUMMY'],'typo3_src'))
	end

	desc 'rmdirStruct: remove all but the scriptfiles files'
	task :rmdirStruct do
		DT3CONST['ROOTDIRS'].each {|key,dirx|
			DT3Logger::log("Removing rootdir #{key}",dirx) 
			FileUtils.rm_r dirx, :force => true  
		}
	end

	desc 'dirstruct: make or update directory structure'
	task :dirStruct do
		DT3CONST['ROOTDIRS'].each {|key,dirx|
			DT3Logger::log("Creating rootdir #{key}",dirx) 
			if not File.directory?(dirx)
				FileUtils.mkdir(dirx)
			end
		}
	end

end

namespace :dev do 
	# read more about version gem @ https://github.com/stouset/version 
	desc 'show version'
	task :version do
		require 'rubygems'
		require 'rake/version_task'
		Rake::VersionTask.new
		Rake::Task["version"].invoke
	end

	desc 'bump version'
	task :versionbump do
		require 'rubygems'
		require 'rake/version_task'
		Rake::VersionTask.new
		Rake::Task["version:bump"].invoke
	end
end

namespace :test do 

	desc 'run all test travis is setup for'
	task :travis => ["test:unit"]

	desc 'run all unit tests'
	task :unit do
		system('rspec spec/test_rakefile_spec.rb')
	end

	task :env do
		system('rspec spec/test_typo3env_spec.rb')
	end

	desc 'run all tests'
	task :all do
		system('rspec spec')
	end
end

namespace :depr do

	desc 'copy all trackedPaths to trackedPathsDir for storage in SCM'
	task :trackDown do
		trackedPaths.each {|path|
			File.makedirs(File.join('trackedPaths',File.dirname(path)))
			FileUtils.cp_r(path, File.join('trackedPaths',File.dirname(path)))
			p path
		}
	end

	desc 'copy all trackedPaths from trackedPathsDir to their location'
	task :trackUp do
		trackedPaths.each {|path|
			FileUtils.cp_r(File.join('trackedPaths',File.dirname(path)),path)
			p path
		}
	end

	desc 'svnStatusExtBundles: per extBundle check the svn status'
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

	desc 'defaultSiteRootFiles: copy files into site root'
	task :defaultSiteRootFiles do

		FileUtils.rm_r rootFilesBundlesDir, :force => true  
		FileUtils.mkdir rootFilesBundlesDir

		CONFIG['defaultSiteRootFiles'].each {|key,val|
			p "checking out root files bundle: "+key
			system("svn co " + val + " "+ rootFilesBundlesDir+"/"+ key)
			p "syncing root files bundle: "+key
			system("rsync --exclude=.git --exclude=.svn -av "+ rootFilesBundlesDir + "/"+ key +'/ web/'+DT3CONST['RELDIRS']['CURRENTDUMMY'] +'/' )
		}

		print "\n"
	end

	desc 'desc: append configured php code to configured files, usefull for overriding modules configurations'
	task :patch_append_php do

		CONFIG['appendPHPToFile'].each {|key,valarr|
			print 'Append task for: '+key+ "\n"
			filename = 'web/'+DT3CONST['RELDIRS']['CURRENTDUMMY']+'/'+valarr['file']
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


end
