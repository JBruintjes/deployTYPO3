class InitDT3
	def self.load_constants

		dt3const = Hash.new

		dt3const['VERSION'] = File.read('VERSION').strip
		dt3const['ROOTDIR'] = Dir.pwd
		dt3const['JOINEDSQL'] = 'joined.sql'
		dt3const['DUMMYDIR'] = File.join('web','dummy') 

		# VERSION
		t3vers_list = CONFIG['TYPO3_VERSION'].split('.')
		dt3const['T3VERSION'] = Hash.new
		dt3const['T3VERSION']['MAJOR'] = t3vers_list[0]
		dt3const['T3VERSION']['MINOR'] = t3vers_list[1]

		if(t3vers_list.count==3)
			dt3const['T3VERSION']['PATCH'] = t3vers_list[2]
		else
			dt3const['T3VERSION']['PATCH'] = nil
		end

		## TODO detect 6.x.x versions and use new filename
		dt3const['TYPO3_LOCALCONF_FILE'] = File.join(dt3const['DUMMYDIR'],'typo3conf','localconf.php')

		dt3const['CURRENTDUMMY'] = 'dummy-'+CONFIG['TYPO3_VERSION']
		dt3const['CURRENTSRCTAR'] = 'typo3_src-'+CONFIG['TYPO3_VERSION']+'.tar.gz'
		dt3const['CURRENTDUMMYTAR'] = 'dummy-'+CONFIG['TYPO3_VERSION']+'.tar.gz'

		dt3const['RELDIRS'] = Hash.new
		dt3const['RELDIRS']['CURRENTDUMMY']='dummy'
		dt3const['RELDIRS']['CURRENTSRC'] = 'typo3_src-'+CONFIG['TYPO3_VERSION']
		dt3const['RELDIRS']['EXTSINGLESDIR'] = File.join("web","dummy",'typo3conf','ext')

		# All defined webdirectories
		dt3const['ROOTDIRS'] = Hash.new
		dt3const['ROOTDIRS']['WEB'] = File.join("web") 
		dt3const['ROOTDIRS']['EXTBUNDLES'] = File.join("extBundles")
		#dt3const['ROOTDIRS']['ROOTFILESBUNDLES'] = File.join("rootFilesBundles")
		dt3const['ROOTDIRS']['TYPO3SOURCE'] = File.join("typo3source")
		dt3const['ROOTDIRS']['TRACKEDPATHS'] = File.join("trackedPaths")
		#dt3const['STRUCTDIRS'] = [webDir, extBundlesDir, typo3sourceDir, trackedPathsDir, rootFilesBundlesDir]

		return dt3const
	end
end

