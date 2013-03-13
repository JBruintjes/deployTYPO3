Description
===========
Toolkit for automating clean TYPO3 installs based on recipes. DeployTYPO3 also
helps you maintain existing TYPO3 environments.

Created and maintained by [Pim Snel](https://github.com/mipmip).
Sponsored by [PAS3](http://www.pas3.com).

QuickStart 1
============

1. Create MySQL database.
2. On your Unix machine in your webdirectory enter the following commands:

```
git clone git://github.com/Lingewoud/deployTYPO3.git
cd deployTYPO3
rake init-config sitename=[Site Name] t3version=[4.x.x] dbname=[database] dbuser=[username] dbpass=[password] dbhost=[hostname]
rake install
```


When the scripts has finished point your browser ```http://yourhost.com/web/dummy``` or ```http://yourhost.com/web/dummy/typo3```. You can now use your fresh vanilla TYPO3

Quickstart 2
============

We are creating a fully functional vagrant/chef-solo example. Read further instructions here: [https://github.com/Lingewoud/vagrant-deployTYPO3](https://github.com/Lingewoud/vagrant-deployTYPO3).

Features
--------
* One command automated deployment  
* One command automated src-upgrade 
* One central configuration recipe
* Installation of TYPO3 dummy and source packages
* Downloading and installing remote extensions
* Downloading and installing extension bundles (directory with a set of extensions)
* Remote TER, Git and Subversion sources
* SQL generation using TYPO3 Install API
* No SQL Image needed, only vanilla ext_tables.sql
* T3x extraction
* Cron-task preparation
* Query typo3.org for available versions
* Support for TYPO3 4.5.x - 4.7.x
* Environment cloning
* Database backups

Advantages
----------
* No need to maintain SQL-images
* Enables create and maintain TYPO3 distributions. 
* Enables extension development using git or subversion
* Enables smart continues integration
* Designed for vagrant and chef integration

Limitations
-----------
* No support yet fot TYPO3 6.x.x

Requirements
============
* Rake
* webserver allowing symlinks
* mysql

Usage
=====

Enter ```rake``` for a list of most important commands

Have a look at the ```config/config.sample.yml``` file how to create a custom recipe.


Contributing to deployTYPO3
===========================
Please report issues and pull-requests at [https://github.com/Lingewoud/deployTYPO3](https://github.com/Lingewoud/deployTYPO3)

Credits
=======
* The superb TYPO3 community

Copyright and license
=====================
Copyright 2013 Pim Snel
Copyright 2013 Lingewoud b.v.

This script is part of the TYPO3 project. The TYPO3 project is
free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

The GNU General Public License can be found at
[http://www.gnu.org/copyleft/gpl.html](http://www.gnu.org/copyleft/gpl.html).
A copy is found in the textfile GPL.txt and important notices to the license
from the author is found in LICENSE.txt distributed with these scripts.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

This copyright notice MUST APPEAR in all copies of the script!










