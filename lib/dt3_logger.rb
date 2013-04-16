require 'logger'

class DT3Logger 
	class << self
		def log(key, val='', type='info')
			if(@logger.nil?) then
				@logger 		= Logger.new("#{DT3CONST['ROOTDIR']}/log/deploytypo3.log")
				@logger.level 	= Logger::DEBUG
			end

			case type
			when 'info'
				@logger.info Time.now.strftime("%b-%d-%Y %H:%M") +' INFO - '+ key+ ': '+ val

				print "\n"
				print Time.now.strftime("%b-%d-%Y %H:%M") +' INFO - '+ key+ ': '+ val
				print "\n"

			when 'error'
					@logger.error Time.now.strftime("%b-%d-%Y %H:%M") +' ERROR - '+ key+ ': '+ val
					#self.mail('Error:'+key,Time.now.to_s+' - '+ key+ ': '+ val)

			when 'warn'
				@logger.warn Time.now.strftime("%b-%d-%Y %H:%M") +' WARNING - '+ key+ ': '+ val
			when 'fatal'
				@logger.fatal Time.now.strftime("%b-%d-%Y %H:%M") +' FATAL - '+ key+ ': '+ val
			when 'unknown'
				@logger.unknown Time.now.strftime("%b-%d-%Y %H:%M") +' UNKNOWN - '+ key+ ': '+ val
			when 'debug'
				if(CONFIG['DEBUG'].to_i==1)
				print "\n"
				print Time.now.strftime("%b-%d-%Y %H:%M") +' DEBUG - '+ key+ ': '+ val
				print "\n"
				end
			end
		end

		def self.mail(subject,message)

			#       from = 'refx3logger@pas3.net'
			#        to = 'pim@lingewoud.nl'

			#Pony.mail(:to => to, :from => from ,:subject => subject,:body => message)

		end
	end
end
