To Do list for deployTYPO3
==========================

Next and first official Version
-------------------------------



Next Version
-------------------------------
* A working [vagrant-deployTYPO3](https://github.com/Lingewoud/vagrant-deployTYPO3)
	* all needed chef-cookbooks 
	* webapp methode
	* chef-DeployTYPO3
* All config-options wel documented
* Unit testing and CI at travis
* Reorganized and renamed lsd_deploytypo3iu
* create ext_emconf.php files
* Git flow
	* Next version task

Planned
-------
* BE Users install
* Pagetree modifications
* TS modifications
* Automatic Recipe extraction from running environments
* Extension dependancy resolver
* Extension version pinning
* Add ```rake task help``` everywhere
* Use nice green colors
* Devide in differce rake class files

Tasks List Prototyping
======================

depreciated
-----------
```
rake defaultSiteRootFiles  # defaultSiteRootFiles: copy files into site root
rake trackDown             # copy all trackedPaths to trackedPathsDir for storage in SCM
```