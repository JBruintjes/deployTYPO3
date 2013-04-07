class InitDT3
	def self.load_constants

		t3const = Hash.new

		t3const['VERSION'] = File.read('VERSION').strip
		t3const['ROOTDIR'] = Dir.pwd
		t3const['JOINEDSQL'] = 'joined.sql'
		t3const['DUMMYDIR'] = File.join('web','dummy') 

		# version
		t3vers_list = CONFIG['typo3']['t3version'].split('.')
p		t3vers_list
		t3const['T3VERSION'] = Hash.new
		t3const['T3VERSION']['MAJOR'] = t3vers_list[0]
		t3const['T3VERSION']['MINOR'] = t3vers_list[1]

		if(t3vers_list.count==3)
			t3const['T3VERSION']['PATCH'] = t3vers_list[2]
		else
			t3const['T3VERSION']['PATCH'] = nil
		end

		## TODO detect 6.x.x versions and use new filename
		t3const['TYPO3_LOCALCONF_FILE'] = File.join(t3const['DUMMYDIR'],'typo3conf','localconf.php')

		return t3const
	end
end

