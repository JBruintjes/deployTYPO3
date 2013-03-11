=begin
 
 Deploy TYPO3 Version 1.4

 Commandline Toolbox for TYPO3 administrator and developers made with Rake. Depends on Subversion.

 (C) 2012 Lingewoud BV <pim@lingewoud.nl>

=end

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
	print "Using sample configurtation, please replace with your own"
	print "\n"
	CONFIG = YAML::load(File.open("config/config.sample.yml"))
end

trackedPaths = CONFIG['trackedPaths'] 

time = Time.new

deploymentName = CONFIG['deploymentName']
deployTypo3Version = "1.4"
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
aliasDir = File.join("alias")
trackedPathsDir = File.join("trackedPaths")
structDirs = [webDir, extBundlesDir, typo3sourceDir, aliasDir, trackedPathsDir, rootFilesBundlesDir]

# Alias destinations for the updateAlias task
aliasDests =  {}
aliasDests['dummy'] 	= '../web/'+currentDummydir
aliasDests['ext'] 		= '../web/'+currentDummydir+'/typo3conf/ext'
aliasDests['typo3conf'] = '../web/'+currentDummydir+'/typo3conf'
aliasDests['typo3temp'] = '../web/'+currentDummydir+'/typo3temp'
aliasDests['fileadmin'] = '../web/'+currentDummydir+'/fileadmin'
aliasDests['templates'] = '../web/'+currentDummydir+'/fileadmin/templates'

upgradingSrc = false

# ----------- DEFAULT TASK ---------- #

task :default => :help

# ----------- BIG TASKS ---------- #
desc 'install: do a complete purge and install'
task :install => [:rmdirStruct, :dirStruct, :getTarballs ,:unpackt3, :scmCheckoutExtBundles, :linkExtBundles, :checkoutExtSingles,:linkExtSingles,:updateAlias, :insertInitConf, :touchinst]

desc 'upgradeSrc: upgrade to newer version'
task :upgradeSrc do

	upgradingSrc = true

	Rake::Task[:getTarballs].invoke
   	Rake::Task[:unpackt3].invoke
   	Rake::Task[:relink].invoke

	print "todo: backup localconf, trackedPaths, install, restore localconf, trackedPaths"
	print "\n"
end

# ----------- SMALL TASKS ---------- #

desc 'desc: show main tasks'
task :help do
	print "DeployTYPO3 version " + deployTypo3Version
	print "\n"
	system("rake -T")
end

desc 'relink: relink templateBundles, extBundles and aliases'
task :relink => [:linkExtBundles, :linkExtSingles, :updateAlias, :linkDummy, :linkTypo3Fix]

desc 'svnStatus: check status of extBundles and trackedPaths'
task :svnStatus do

    	Rake::Task[:svnStatusExtBundles].invoke

	print "checking de subversion status of tracked paths"
	print "\n"
	system("svn status " + trackedPathsDir)
end

desc 'svnUpDryRunExtBundles: per extBundle see whats going to be updated'
task :svnUpDryRunExtBundles do
	print "dryrun updating extension bundles"
	print "\n"

	Dir.foreach(File.join("extBundles")) {|rdir| 
		if checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			p "In Extension Bundle #{rdir}"

			system("svn merge --dry-run -r BASE:HEAD " + File.join("extBundles",rdir))
		end
	}
end

desc 'svnUpExtBundles: per extBundle update working copy'
task :svnUpExtBundles do
	p "updating extension bundles"

	Dir.foreach(File.join("extBundles")) {|rdir| 
		if checkValidDir(rdir) and File.directory?(File.join("extBundles",rdir))
			p "In Extension Bundle #{rdir}"

			system("svn up " + File.join("extBundles",rdir))
		end
	}
end


#desc 'checkoutExtSingles: checkout all single extensions defined in config.yml'
task :checkoutExtSingles do
	if not CONFIG['extSingles'].nil?
		p "checking out single extension"

		FileUtils.rm_r extSinglesDir, :force => true  
		FileUtils.mkdir extSinglesDir

		CONFIG['extSingles'].each {|key,valarr|

			revisionSubString = ''
			if valarr['revision'].is_a?(Integer)
				revisionSubString = ' -r '+ valarr['revision'].to_s + ' '
				p revisionSubString.to_s
			end


			p("svn co "+ revisionSubString + valarr['svnurl'] + " " + extSinglesDir+ "/"+ key)
			system("svn co "+ revisionSubString + valarr['svnurl'] + " " + extSinglesDir+ "/"+ key)
		}
	end
end

desc 'scmCheckoutExtBundles: checkout all ext bundles defined in config.yml'
task :scmCheckoutExtBundles do
	p "checking out extension bundles"

	FileUtils.rm_r "extBundles", :force => true  
	FileUtils.mkdir "extBundles"

	if(CONFIG['extBundlesSvnUrl']) 
		CONFIG['extBundlesSvnUrl'].each {|key,val|
			system("svn co " + val + " extBundles/"+ key)
		}
	end

	if(CONFIG['extBundlesGitUrl']) 
		CONFIG['extBundlesGitUrl'].each {|key,val|
			system("git clone " + val + " extBundles/"+ key)
		}
	end
end

desc 'scmCheckoutNewExtBundles: checkout missing ext bundles defined in config.yml'
task :scmCheckoutNewExtBundles do

	p "checking out new missing extension bundles"
	if(CONFIG['extBundlesSvnUrl']) 
		CONFIG['extBundlesSvnUrl'].each {|key,val|
			if not File.directory?(File.join("extBundles",key))
				system("svn co " + val + " extBundles/"+ key)
			end
		}
	end

	if(CONFIG['extBundlesGitUrl']) 
		CONFIG['extBundlesGitUrl'].each {|key,val|
			if not File.directory?(File.join("extBundles",key))
				system("git clone " + val + " extBundles/"+ key)
			end
		}
	end

end

desc 'touchinst: Create a file typo3conf/ENABLE_INSTALL_TOOL'
task :touchinst do
	p "creating ENABLE_INSTALL_TOOL"
	
	system('touch web/'+currentDummydir+'/typo3conf/ENABLE_INSTALL_TOOL')
end

desc 'info: Show main TYPO3 configured settings'
task :info do
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

desc 'dbbackup: dump database'
task :dbbackup do
	dbsetarr = getDbSettings()

	t = Time.now
	datetime = t.strftime("%Y-%m-%d-time-%H:%M")   #=> "Printed on 04/09/2003"

	print "Dumping database"
	print "\n"
	system("mysqldump " +  dbsetarr[3]  + " -u"+ dbsetarr[0] + " -p"+ dbsetarr[1] +" > "+ dbsetarr[3] + datetime + ".sql")
	print "\n"

end

desc 'rmcache: remove typo3conf cache & temp files'
task :rmcache do
	p "removing cache files"
	system("rm -Rf alias/typo3temp/*")
	p "truncating typo3temp"
	system("rm alias/typo3conf/temp_CACHED_*")
end

desc 'copy all trackedPaths to trackedPathsDir for storage in SCM'
task :trackDown do
	#get dir struct relative to alias/[....]/
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

#desc 'getTarballs: download remote typo3 tarballs and store them in typo3source'
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

#desc 'unpackt3: purge & unpack tarballs of current version'
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

task :purge do
	print "remove complete typo3 deployment? Enter YES to confirm: " 
	cleanConfirm = STDIN.gets.chomp
	if(cleanConfirm.downcase=='yes')
		system('rm -Rf web alias trackedPaths typo3source extBundles '+rootFilesBundlesDir)
	end
end

#remove?
#desc 'packt3: pack tarballs to typo3source'
#task :packt3 do
#	system('tar --directory web -c -z -f typo3source/dummy-'+currentVersion +'.tar.gz dummy-'+currentVersion)
#	system('tar --directory web -c -z -f typo3source/typo3_src-'+currentVersion+'.tar.gz typo3_src-'+currentVersion)
#end

#desc 'linkTypo3Fix: create symlink to typo3 to fix certain backpath references'
task :linkTypo3Fix do
	print "symlink typo3 fix"
	print "\n"
	system('ln -sf '+ File.join("web",currentDummydir,'typo3') +' typo3')
end

#desc 'linkExtBundles: create symlinks in the structure to the dirs in the bundles'
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

desc 'rmdirStruct: remove all but the scriptfiles files'
task :rmdirStruct do
	structDirs.each {|dirx|
		FileUtils.rm_r dirx, :force => true  
	}

	#??????
	#rmsymlink(File.join('..','typo3'))
end

#desc 'dirstruct: make or update directory structure'
task :dirStruct do
	structDirs.each {|dirx|
		if not File.directory?(dirx)
			FileUtils.mkdir(dirx)
		end
	}
end

#desc 'updateAlias: update all aliases into the alias-dir'
task :updateAlias do
	aliasDests.each {|k,v|
		rmsymlink("alias/" + k)
		system("ln -sf " + v + " alias/" + k)
	}
end

task :insertInitConf do
	if(CONFIG.has_key?('localconf') && CONFIG['localconf'].has_key?('initConf'))
		filename = "alias/typo3conf/"+$localconfFile

		last_line = 0
		file = File.open(filename, 'r+')
		file.each { last_line = file.pos unless file.eof? }
		file.seek(last_line, IO::SEEK_SET)
		file.write(CONFIG['localconf']['initConf'])
		file.write("?>")
		file.close
	end
end

desc 'copytypo3to: copy complete typo3 environment including deployment scripts and database'
task :copytypo3to do
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
		print "rake copytypo3to destpath=[/newpath] destdbname=[database] destdbuser=[username] destdbpass=[password]"
		print "\n"
		print "\n"
		print "Example:\n"
		print "rake copytypo3to destpath=../typo3copy destdbname=testdb destdbuser=testdbuser destdbpass=testdbpasswordv"
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
	system("rm -Rf "+ ENV['destpath'] +'/alias/typo3conf/temp*')
	system("rm -Rf "+ ENV['destpath'] +'/alias/typo3temp/*')

	setLocalconfDbSettings(ENV['destdbname'],ENV['destdbuser'],ENV['destdbpass'], 'localhost', ENV['destpath']+'/alias/typo3conf/'+$localconfFile)
end

desc 'copydb: copy complete database structure and schema to a new database. This db must already exist'
task :copydb do
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
		print "rake copydb destdbname=[database]"
		print "\n"
		print "\n"
		print "Example:\n"
		print "rake copydb destdbname=testdb"
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

desc 'setLive: make link a dir lower indicating this is live'
task :setLive do

	if(!deploymentName)
		deploymentName = 'noName-please-configure'
	end

	rmsymlink('../TYPO3Live-'+deploymentName)

	print "symlink this as live environment"
	print "\n"
	system('ln -sf ' + Dir.pwd + ' ' + File.join("..",'TYPO3Live-'+deploymentName))
end

desc 'appendPHPToFile: append configured php code to configured files, usefull for overriding modules configurations'
task :appendPHPToFile do

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

desc 'defaultSiteRootFiles: copy files into site root'
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


desc 'cronSchedTask: echo cron confguration'
task :cronSchedTask do

	livePath = File.expand_path(File.join(Dir.pwd,"..",'TYPO3Live-'+deploymentName))

	print "CRON SCHEDULAR CONFIGURATION"
	print "\n"
	print '*/5 * * * * root '+livePath+'/web/dummy/typo3/cli_dispatch.phpsh scheduler'
	print "\n"
	print "echo '*/5 * * * * root "+livePath+"/web/dummy/typo3/cli_dispatch.phpsh scheduler' > /etc/cron.d/typo3-"+deploymentName
	print "\n"

end

desc 't3versions: show available TYPO3 versions'
task :t3versions do

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

def getDbSettings()
	cmd = "php -r \'include \"alias/typo3conf/"+$localconfFile+"\";echo \"$typo_db_username $typo_db_password $typo_db_host $typo_db\";\'"
	dbsettings =%x[ #{cmd} ]
	dbsettings.split(' ');
end

def setLocalconfDbSettings(db,user,pass,host='localhost',outfile='alias/typo3conf/localconf.new.php')
	
	text = File.read('alias/typo3conf/'+$localconfFile)
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
	if dir!= '..' and dir != '.' and dir!= '.svn'
		return true
	else
		return false
	end
end
