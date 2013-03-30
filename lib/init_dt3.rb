class InitDT3
	def self.load_constants

		t3const = Hash.new

		t3const['VERSION'] = File.read('VERSION').strip
		t3const['ROOTDIR'] = Dir.pwd

		#if CONFIG['typo3']['t3version'][0].to_i > 4
			t3const['TYPO3_LOCALCONF_FILE'] = 'web/dummy/typo3conf/localconf.php'
		#else
		#	t3const['TYPO3_LOCALCONF_FILE'] = 'web/dummy/typo3conf/localconf.php'
		#end
		return t3const
	end
end

