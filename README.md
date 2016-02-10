wlst-scripts
============

Set of WSLT scripts for manage WebLogic instances.

*manageServers.py*
----------------

Main script than connect to AdminServer via wslt.sh.
Usage:
./wlst.sh manageServers.py -u username -p password -a adminUrl [:] -n ServerName -c [stop:start:restart:status:stopall:startall:statusall]

* maybe you need a bash script wrapper to pass an arguments
* if you have problem with passing arguments to wlst.sh, try to remove space between parameter and valud - i.e. manageServers.py -uusername -ppaswword -aadminUrl -nservername -caction

*init.d scripts:*
---------------

* **single-node-full-initd/weblogic.sh**: complete script that start/stop nodemanager, admin server and managed servers
