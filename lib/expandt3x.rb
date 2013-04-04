class ExpandT3x

	def self.expand(t3xfile, extdir)
		cmd = "/usr/bin/php -c lib/expandt3x/php.ini lib/expandt3x/expandt3x.php #{t3xfile}  #{extdir}"
		p cmd
		system(cmd)
#		stdout = `#{cmd}`
#		p stdout
#		return stdout
	end
end
