=begin

 Commandline Toolbox for TYPO3 administrator and developers made with Rake. 

 (C) 2013 Lingewoud BV <pim@lingewoud.nl>

Copyright 2013 Pim Snel Copyright 2013 Lingewoud b.v.

This script is part of the TYPO3 project. The TYPO3 project is free software;
you can redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation; either version 2 
of the License, or (at your option) any later version.

The GNU General Public License can be found at 
http://www.gnu.org/copyleft/gpl.html. A copy is found in the textfile GPL.txt
and important notices to the license from the author is found in LICENSE.txt
distributed with these scripts.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details.

This copyright notice MUST APPEAR in all copies of the script!

=end
namespace :env do
	desc 'desc: make link a dir lower indicating this is live'
	task :livelink do

		if(!@deploymentName)
			@deploymentName = 'noName-please-configure'
		end

		rmsymlink('../TYPO3Live-'+@deploymentName)

		print "symlink this as live environment"
		print "\n"
		system('ln -sf ' + Dir.pwd + ' ' + File.join("..",'TYPO3Live-'+@deploymentName))
	end

	desc 'desc: echo cron confguration'
	task :cron do

		livePath = File.expand_path(File.join(Dir.pwd,"..",'TYPO3Live-'+@deploymentName))

		print "CRON SCHEDULAR CONFIGURATION"
		print "\n"
		print '*/5 * * * * root '+livePath+'/web/dummy/typo3/cli_dispatch.phpsh scheduler'
		print "\n"
		print "echo '*/5 * * * * root "+livePath+"/web/dummy/typo3/cli_dispatch.phpsh scheduler' > /etc/cron.d/typo3-"+@deploymentName
		print "\n"
	end
end


