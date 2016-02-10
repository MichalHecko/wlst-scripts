#!/bin/sh
#
# chkconfig:   345 85 15
# description: Oracle Weblogic service init script (nodeadmin + admin server + managed servers)
 
### BEGIN INIT INFO
# Provides: weblogic
# Required-Start: $network $local_fs
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Short-Description: per domain Oracle Weblogic service.
# Description: Starts and stops per domain Oracle Weblogic.
### END INIT INFO
 
. /etc/rc.d/init.d/functions
 
#### BEGIN CUSTOM ENV
DOMAIN_HOME="/u01/oracle/config/domains/dms_test"
MANAGE_SERVERS_SCRIPT="/u01/oracle/script/manageServers.sh"
WLS_ADMIN_SERVER_NAME="dms01admin"
#### END CUSTOM ENV
 
NM_SERVICE_NAME="NodeManager"
NM_PROCESS_STRING="^.*$DOMAIN_HOME.*weblogic.NodeManager.*"
NM_PROGRAM_START="$DOMAIN_HOME/bin/startNodeManager.sh"
NM_LOCKFILE="/var/lock/subsys/$NM_SERVICE_NAME"
NM_OUT_FILE="$DOMAIN_HOME/bin/startNodeManager.out"
 
WLS_SERVICE_NAME="WebLogic"
WLS_PROCESS_STRING="^.*-Dweblogic.Name=$WLS_ADMIN_SERVER_NAME.*weblogic.Server.*"
WLS_PROGRAM_START="$DOMAIN_HOME/bin/startWebLogic.sh"
WLS_PROGRAM_STOP="$DOMAIN_HOME/bin/stopWebLogic.sh"
WLS_LOCKFILE="/var/lock/subsys/$WLS_SERVICE_NAME"
WLS_OUT_FILE="$DOMAIN_HOME/bin/startWebLogic.out"
 
RETVAL=0

 
start_NM() {
        OLDPID=`/usr/bin/pgrep -f $NM_PROCESS_STRING`
        if [ ! -z "$OLDPID" ]; then
            echo "$NM_SERVICE_NAME is already running (pid $OLDPID) !"
            echo
	    exit 1
        fi
        echo -n $"Starting $NM_SERVICE_NAME ... "
 
	rm -f $NM_LOCKFILE
        rm -f $NM_OUT_FILE

	su -c "$NM_PROGRAM_START >> $NM_OUT_FILE 2>&1 &" oracle
 
        RETVAL=$?
        if [ $RETVAL -eq 0 ] ; then
          wait_for $NM_OUT_FILE "socket listener started on port" $NM_LOCKFILE
        else
          echo "FAILED: $RETVAL. Please check $NM_OUT_FILE for more information."
        fi
        echo
}

start_WLS() {
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ ! -z "$OLDPID" ]; then
            echo "$WLS_SERVICE_NAME is already running (pid $OLDPID) !"
            echo
	    exit 1
        fi
        echo -n $"Starting $WLS_SERVICE_NAME ... "

	rm -f $WLS_LOCKFILE
        rm -f $WLS_OUT_FILE

	su -c "$WLS_PROGRAM_START >> $WLS_OUT_FILE 2>&1 &" oracle
 
        RETVAL=$?
        if [ $RETVAL -eq 0 ] ; then
          wait_for $WLS_OUT_FILE "Server state changed to RUNNING" $WLS_LOCKFILE
        else
          echo "FAILED: $RETVAL. Please check $WLS_OUT_FILE for more information."
        fi
        echo
}


start_MANAGED() {
        echo -n $"Starting managed servers ... "
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
		
	    su -c "$MANAGE_SERVERS_SCRIPT all startall" oracle
 
            RETVAL=$?
            echo "OK"
        else
            /bin/echo "FAILED: WLS is not running"
        fi
	echo
}
 
wait_for() {
    res=$(cat "$1" | fgrep -c "$2")
    count=120
    while [[ ! $res -gt 0 ]] && [[ $count -gt 0 ]]
    do
        sleep 1
        count=$(($count - 1))
        res=$(cat "$1" | fgrep -c "$2")
    done
    res=$(cat "$1" | fgrep -c "$2")
    if [ ! $res -gt 0 ]; then
        echo "FAILED or took too long time to start. Please check $1 for more information."
    else
        echo "OK"
        touch $3
    fi
}
 
stop_NM() {
        echo -n $"Stopping $NM_SERVICE_NAME ... "
        OLDPID=`/usr/bin/pgrep -f $NM_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
            echo -n "(pid $OLDPID) "
            /bin/kill -TERM $OLDPID
 
            RETVAL=$?
            echo "OK"
            rm -f $NM_LOCKFILE
	    rm -f $NM_OUT_FILE
        else
            /bin/echo "$NM_SERVICE_NAME is stopped"
        fi
        echo
}

stop_WLS() {
        echo -n $"Stopping $WLS_SERVICE_NAME ... "
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
            echo -n "(pid $OLDPID) "
		
	    su -c "$WLS_PROGRAM_STOP > /dev/null" oracle
	    RETVAL=$?
            if [ $RETVAL -eq 0 ] ; then
                wait_for $WLS_OUT_FILE "Server state changed to SHUTTING_DOWN" $WLS_LOCKFILE
            else
                echo "FAILED: $RETVAL. Please check $WLS_OUT_FILE for more information."
            fi
 
            RETVAL=$?
            echo "OK"
            rm -f $WLS_LOCKFILE
	    rm -f $WLS_OUT_FILE
        else
            /bin/echo "$WLS_SERVICE_NAME is stopped"
        fi
        echo
}

stop_MANAGED() {
        echo -n $"Stopping managed servers ... "
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
		
	    su -c "$MANAGE_SERVERS_SCRIPT all stopall" oracle
 
            RETVAL=$?
            echo "OK"
        else
            /bin/echo "Managed servers are stopped"
        fi
	echo
}
 
restart() {
        stop
        sleep 10
        start
}

status_NM() {
        OLDPID=`/usr/bin/pgrep -f $NM_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
            /bin/echo "$NM_SERVICE_NAME is running (pid: $OLDPID)"
        else
            /bin/echo "$NM_SERVICE_NAME is stopped"
        fi
        echo
        RETVAL=$?
}

status_WLS() {
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
            /bin/echo "$WLS_SERVICE_NAME is running (pid: $OLDPID)"
        else
            /bin/echo "$WLS_SERVICE_NAME is stopped"
        fi
        echo
        RETVAL=$?
}

status_MANAGED() {
        OLDPID=`/usr/bin/pgrep -f $WLS_PROCESS_STRING`
        if [ "$OLDPID" != "" ]; then
	    su -c "$MANAGE_SERVERS_SCRIPT all statusall" oracle
        else
            /bin/echo "Managed servers are stopped"
        fi
        echo
        RETVAL=$?
} 
 
case "$1" in
  start)
	start_NM
	start_WLS
	start_MANAGED
        ;;
  stop)
	stop_MANAGED
	stop_WLS
	stop_NM
        ;;
  restart|force-reload|reload)
        restart
        ;;
  condrestart|try-restart)
        [ -f $NM_LOCKFILE ] && restart
        ;;
  status)
	status_NM
	status_WLS
	status_MANAGED
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
        exit 1
esac
 
exit $RETVAL
