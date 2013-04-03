class InitDT3
	def self.load_constants

		t3const = Hash.new

		t3const['VERSION'] = File.read('VERSION').strip
		t3const['ROOTDIR'] = Dir.pwd
		t3const['JOINEDSQL'] = 'joined.sql'
		t3const['DUMMYDIR'] = File.join('web','dummy') 

		## TODO detect 6.x.x versions and use new filename
		t3const['TYPO3_LOCALCONF_FILE'] = File.join(t3const['DUMMYDIR'],'typo3conf','localconf.php')

		return t3const
	end
end

