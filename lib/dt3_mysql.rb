class DT3MySQL

	def self.flush_tables
		DT3Logger::log('Flushing tables') 
		tablelist =	 `#{self.create_mysql_base_command} -e "show tables" | grep -v Tables_in | grep -v "+"`
		dropsql = ''
		 tablelist.split("\n").each {|table|
			dropsql +="drop table #{table};" 
		 }
		 self.mysql_execute(dropsql)
		return true
	end

	def self.show_tables
		return self.mysql_execute('show tables')
	end

	def self.create_mysql_base_command_with(user,host,pass,db)
		cmd = "mysql -u#{user} -h#{host} -p#{pass} #{db} "
		return cmd
	end

	def self.create_mysql_base_command
		cmd = self.create_mysql_base_command_with(CONFIG['typo3']['dbuser'],CONFIG['typo3']['dbhost'],CONFIG['typo3']['dbpass'],CONFIG['typo3']['dbname'])
	end

	def self.mysql_execute(sql)
		DT3Logger::log('Executing SQL',sql) 
		cmd = self.create_mysql_base_command + "-e \"#{sql}\""
		stdout = `#{cmd}`
		return stdout
	end

	def self.mysqldump_to(dbname,user,pass,host,outputfile)
		system("mysqldump #{dbname} -u#{user} -p#{pass} -h #{host} > #{outputfile}")
	end

	def self.copy_database(user,pass,host,indb,outdb)
		system("mysqldump #{indb} -u#{root} -p#{pass} -h#{host} | mysql -u#{user} -p#{pass} -h#{host} #{outdb}")
	end
end
