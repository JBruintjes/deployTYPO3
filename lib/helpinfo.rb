class HelpInfo

	def self.print_help(expert=false)

		print "\n"
		print "DeployTYPO3 version " + DT3CONST['VERSION']
		print "\n"
		print "\n"
		help = `rake -T`
		
		list_main =['help','init','inst','bak','env','db','ext','t3org']
		list_exp =['dev','test','sub','depr']

		if(expert)
			list = list_main.concat(list_exp)
		else
			list = list_main
		end
		
		list.each {|key|
			help.each { |line|
				if (not line[0,4]== '(in ' && line!='')
					if(line[5,key.length+1]==key+':')
						print line
					end
				end
			}
			print "\n"
		}

		print "\n"
		print "\n"
	end
end
