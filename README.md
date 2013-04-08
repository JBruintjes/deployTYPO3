# DeployTYPO3 [![Build Status](https://travis-ci.org/Lingewoud/deployTYPO3.png?branch=master)](https://travis-ci.org/Lingewoud/deployTYPO3)

![image](http://picdrop.t3lab.com/iG3nIv9Kla.png)

## Description

Toolkit for automating clean TYPO3 installs based on recipes. DeployTYPO3 also
helps you maintain existing TYPO3 environments.

Created and maintained by [Pim Snel](https://github.com/mipmip).
Sponsored by [PAS3](http://www.pas3.com) and [Lingewoud](http://www.lingewoud.com).

## Features

* One command automated deployment  
* One command automated src-upgrade 
* One central configuration recipe
* Installation of TYPO3 dummy and source packages
* Downloading and installing remote extensions
* Downloading and installing extension bundles (directory with a set of extensions)
* Remote TER, Git sources
* SQL generation using TYPO3 Install API
* No SQL Image needed, only vanilla ext_tables.sql
* T3x extraction
* Extension EM Configuration
* Localconf GLOBAL configuration
* Cron-task preparation
* Query typo3.org for available versions
* Support for TYPO3 4.7.x
* Environment cloning
* Database backups

## Advantages
* No need to maintain SQL-images
* Enables create and maintain TYPO3 distributions. 
* Enables extension development using git or subversion
* Enables smart continues integration
* Designed for vagrant and chef integration

## QuickStart 1

On your Unix machine in your webdirectory enter the following commands:

```
# Create a MySQL database.

mysqladmin create typo3_db -uroot -p

# clone deployTYPO3 into your webdirectory
cd /var/www
git clone git://github.com/Lingewoud/deployTYPO3.git
cd deployTYPO3

# Create an initial config.yml file that will be your TYPO3 recipe.
# 
# rake init:conf
#  usage: 
#  rake init:conf t3version=[4.x.x] dbname=[database] dbuser=[username] dbpass=[password] dbhost=[hostname]
#
# e.g.
rake init:conf t3version=4.7.9 dbname=typo3_db dbuser=typo3_db dbpass=test dbhost=localhost

rake inst:all
```

When the scripts has finished point your browser ```http://yourhost.com/web/dummy``` or ```http://yourhost.com/web/dummy/typo3```. You can now use your fresh vanilla TYPO3

## Quickstart 2

We are developing a fully functional vagrant/chef-solo example. Read further instructions here: [https://github.com/Lingewoud/vagrant-deployTYPO3](https://github.com/Lingewoud/vagrant-deployTYPO3).

## Limitations

Currently, deployTYPO3 only supports TYPO3 v4.7.x, we will add other versions soon.

* No support yet fot TYPO3 6.x.x
* No support yet fot TYPO3 4.6.x
* No support yet fot TYPO3 4.5.x

## Requirements
* Rake
* See Gemfile for needed gems
* webserver allowing symlinks
* mysql

## Usage

Have a look at the ```config/config.sample.yml``` file how to create a custom recipe.

Enter ```rake help``` for an up to date list of most important commands

```
$ rake help
(in /var/customers/webs/pim/deployTYPO3)

DeployTYPO3 version 1.5.1

rake help                       # desc: show main tasks
rake help_exp                   # desc: show all including dev and sub tasks

rake init:conf                  # desc: generates a config.yml

rake inst:all                   # desc: purge and install the complete configured TYPO3 environment
rake inst:man                   # desc: purge and download the complete environment but do not setup the localconf & db.
rake inst:min                   # desc: purge and install the configured TYPO3 environment without external extensions

rake env:copy                   # desc: copy complete typo3 environment including deployment scripts and database
rake env:cron                   # desc: echo cron confguration
rake env:flush_cache            # desc: remove typo3conf cache & temp files
rake env:info                   # desc: Show main TYPO3 configured settings
rake env:livelink               # desc: make link a dir lower indicating this is live
rake env:purge                  # desc: purges all typo3 files and extensions.
rake env:relink                 # desc: relink extension bundles and extensions
rake env:touchinst              # desc: Create a file web/dummy/typo3conf/ENABLE_INSTALL_TOOL
rake env:upgrade_src            # desc: upgrade to newer version

rake db:backup                  # desc: active database to sql-file
rake db:copy                    # desc: copy complete database structure and schema to a new database.
rake db:flush                   # desc: delete all tables
rake db:install                 # desc: Install all SQL files
rake db:tables                  # desc: show all tables

rake t3org:lastversions         # desc: show last TYPO3 versions
rake t3org:versions             # desc: show available TYPO3 versions

```

## Contributing to deployTYPO3
Please report issues and pull-requests at [https://github.com/Lingewoud/deployTYPO3](https://github.com/Lingewoud/deployTYPO3)

## Credits

* The superb [TYPO3](http://www.typo3.org) project with it's [smart community](https://typo3.org/community/)

## Copyright and license

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
