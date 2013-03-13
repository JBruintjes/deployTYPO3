To Do list for deployTYPO3
==========================

Next and first official Version
-------------------------------
* Add GPL everywhere needed
* A working [vagrant-deployTYPO3](https://github.com/Lingewoud/vagrant-deployTYPO3)
	* all needed chef-cookbooks 
	* webapp methode
	* chef-DeployTYPO3
* Complete localconf.php generation, maintainance
	* before everything first generate localconf
* Restructured task-names and descriptions
* All config-options wel documented
* Unit testing and CI at travis
* Reorganized and renamed lsd_deploytypo3iu
* create ext_emconf.php files
* Git flow
	* Next version task
* init.php security workaround
	* comment in init.php

	```
	#$BE_USER->checkCLIuser();
	#$BE_USER->backendCheckLogin(); // Checking if there's a user logged in
	```

Planned
-------
* BE Users install
* Pagetree modifications
* TS modifications
* Automatic Recipe extraction from running environments
* Extension dependancy resolver
* Extension version pinning