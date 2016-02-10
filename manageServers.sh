#!/bin/sh

mypwd="`pwd`"

case `uname -s` in
Windows_NT*)
  CLASSPATHSEP=\;
;;
CYGWIN*)
  CLASSPATHSEP=\;
;;
*)
  CLASSPATHSEP=:
;;
esac


SCRIPTPATH="/u01/oracle/products/fmw1221/oracle_common/common/bin/"

# Set CURRENT_HOME...
CURRENT_HOME=`cd "${SCRIPTPATH}/../.." ; pwd`
export CURRENT_HOME

# Set the MW_HOME relative to the CURRENT_HOME...
MW_HOME=`cd "${CURRENT_HOME}/.." ; pwd`
export MW_HOME

# Set the home directories...
. "${SCRIPTPATH}/setHomeDirs.sh"

# Set the DELEGATE_ORACLE_HOME to CURRENT_HOME if it's not set...
ORACLE_HOME="${DELEGATE_ORACLE_HOME:=${CURRENT_HOME}}"
export DELEGATE_ORACLE_HOME ORACLE_HOME

# Some scripts in WLST_HOME reference ORACLE_HOME
WLST_PROPERTIES="${WLST_PROPERTIES} -DORACLE_HOME='${ORACLE_HOME}'"
export WLST_PROPERTIES


umask 027

# set up common environment
if [ ! -z "${WLS_NOT_BRIEF_ENV}" ]; then
  if [ "${WLS_NOT_BRIEF_ENV}" = "true" -o  "${WLS_NOT_BRIEF_ENV}" = "TRUE"  ]; then
    WLS_NOT_BRIEF_ENV=
    export WLS_NOT_BRIEF_ENV
  fi
else
    WLS_NOT_BRIEF_ENV=false
    export WLS_NOT_BRIEF_ENV
fi

. "${MW_HOME}/oracle_common/common/bin/commBaseEnv.sh"

if [ -f "${SCRIPTPATH}/cam_wlst.sh" ] ; then
  . "${SCRIPTPATH}/cam_wlst.sh"
fi

CLASSPATH="${WLST_EXT_CLASSPATH}${CLASSPATHSEP}${FMWCONFIG_CLASSPATH}"

export CLASSPATH


if [ "${WLS_NOT_BRIEF_ENV}" = "" ] ; then
  echo
  echo CLASSPATH=${CLASSPATH}
fi

JVM_ARGS="${WLST_PROPERTIES} ${JVM_D64} ${UTILS_MEM_ARGS} ${CONFIG_JVM_ARGS}"
if [ -d "${JAVA_HOME}" ]; then
 eval '"${JAVA_HOME}/bin/java"' ${JVM_ARGS} weblogic.WLST manageServers.py -u weblogic -p car0dejnic4 -a localhost:17001 -n $1 -c $2
else
 exit 1 
fi

