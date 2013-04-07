class HelpInfo

	def self.print_help(expert=false)

		print "\n"
		print "DeployTYPO3 version " + DT3CONST['VERSION']
		print "\n"
		print "\n"
		help = `rake -T`

		listhelp = []
		listenv = []
		listdb = []
		listinst = []
		listext = []
		listinit = []
		listt3org = []

		listdev = []
		listtest = []
		listsub = []
		listdepr = []

		help.each do |line|
			#		p line[0,4]
			if (not line[0,4]== '(in ' && line!='')
				if(line[5,4]=='env:')
					listenv << line.chomp
				elsif(line[5,3]=='db:')
					listdb << line.chomp
				elsif(line[5,5]=='inst:')
					listinst << line.chomp
				elsif(line[5,4]=='ext:')
					listext << line.chomp
				elsif(line[5,6]=='t3org:')
					listt3org << line.chomp
				elsif(line[5,5]=='init:')
					listinit << line.chomp
				elsif(line[5,4]=='help')
					listhelp << line.chomp
				elsif(line[5,4]=='dev:')
					listdev << line.chomp
				elsif(line[5,5]=='test:')
					listtest << line.chomp
				elsif(line[5,4]=='sub:')
					listsub << line.chomp
				elsif(line[5,5]=='depr:')
					listdepr << line.chomp
				end
			else
				#list << line.chomp
			end
		end

		listhelp.each {|line|
			print line
			print "\n"
		}

		print "\n"
		listinit.each {|line|
			print line
			print "\n"
		}

		print "\n"
		listinst.each {|line|
			print line
			print "\n"
		}


		print "\n"
		listenv.each {|line|
			print line
			print "\n"
		}
		print "\n"
		listdb.each {|line|
			print line
			print "\n"
		}

		print "\n"
		listt3org.each {|line|
			print line
			print "\n"
		}
		if(expert)
			print "\n"
			listdev.each {|line|
				print line
				print "\n"
			}
			print "\n"
			listtest.each {|line|
				print line
				print "\n"
			}

			print "\n"
			listext.each {|line|
				print line
				print "\n"
			}
			print "\n"
			listsub.each {|line|
				print line
				print "\n"
			}

			print "\n"
			listdepr.each {|line|
				print line
				print "\n"
			}
		end

		print "\n"
		#print help
		print "\n"

	end



end
