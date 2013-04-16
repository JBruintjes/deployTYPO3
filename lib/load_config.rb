require "yaml"

class LoadConfig
	def self.load_config
		if (File.file?("config/config.yml") or File.symlink?('config/config.yml'))
			config = YAML::load(File.open("config/config.yml"))
		else
			print "No file or symlink found. Using sample configuration, please replace with your own"
			print "\n"
			config = YAML::load(File.open("config/config.sample.yml"))
		end
		return config
	end
end
