#!/bin/bash
set -e
set -x
echo $(basename $0)
sleep 5
id

# if VERTICA_DATABASE is not provided use default one: "docker"
VERTICA_DATABASE="${VERTICA_DATABASE:-docker}"
# if VERTICA_PASSWORD is provided, use it as DB password, otherwise empty password
if [ -n "$VERTICA_PASSWORD" ]; then export DBPW="-p $VERTICA_PASSWORD" VSQLPW="-w $VERTICA_PASSWORD"; else export DBPW="" VSQLPW=""; fi
# if license is provided, use file otherwise use CE license
if [ -n "$VERTICA_LICENSE" ] && [ ! -f  $VERTICA_LICENSE ] ; then
	echo "$VERTICA_LICENSE not found"
	exit 1
fi
VERTICA_LICENSE="${VERTICA_LICENSE:-CE}"
VERTICA_DATA="${VERTICA_DATA:-/home/dbadmin/local-data}"
VERTICA_HOSTS="${VERTICA_HOSTS:-127.0.0.1}"

# Vertica should be shut down properly
function shut_down() {
  echo "Shutting Down"
  vertica_proper_shutdown
  echo 'Saving configuration'
  mkdir -p ${VERTICA_DATA}/config
  /bin/cp /opt/vertica/config/admintools.conf ${VERTICA_DATA}/config/admintools.conf
}

function vertica_proper_shutdown() {
  # do it only if db exists
  echo 'Vertica: Closing active sessions'
  /opt/vertica/bin/vsql -U dbadmin -d ${VERTICA_DATABASE} ${VSQLPW} -c 'SELECT CLOSE_ALL_SESSIONS();'
  echo 'Vertica: Flushing everything on disk'
  /opt/vertica/bin/vsql -U dbadmin -d ${VERTICA_DATABASE} ${VSQLPW} -c 'SELECT MAKE_AHM_NOW();'
  echo 'Vertica: Stopping database'
  /opt/vertica/bin/admintools -t stop_db ${DBPW} -d ${VERTICA_DATABASE} -i
}

function fix_filesystem_permissions() {
  chown -R dbadmin:verticadba "${VERTICA_DATA}"
  chown dbadmin:verticadba /opt/vertica/config/admintools.conf
}

# Clean shutdown
# TODO: trap signal 
trap "shut_down" KILL TERM HUP INT

echo 'Starting up'
if [ ! -f /opt/vertica/config/admintools.conf ]; then
  echo "# Setup vertica"
  install_opts="--debug --license ${VERTICA_LICENSE} --accept-eula --dba-user-password-disabled --failure-threshold NONE --hosts $VERTICA_HOSTS --no-system-configuration --ignore-aws-instance-type -T --data-dir $VERTICA_DATA --clean "
  sudo /opt/vertica/sbin/install_vertica $install_opts
fi
chown $USER. /opt/vertica/config/admintools.conf

if [ ! -d "/opt/vertica/config/licensing/" ] || [ ! -f  /opt/vertica/config/share/license.key ] ; then
  echo "# license"
  mkdir -p /opt/vertica/config/licensing/
  chown $USER. /opt/vertica/config/licensing/
  sudo cp -a $HOME/licensing/ce/* /opt/vertica/config/licensing/
  cp -a $HOME/licensing/ce/* /opt/vertica/config/share/license.key
fi

# If no db create it
# else start db
echo 'Starting db'
if [ ! -d "$VERTICA_DATA/$VERTICA_DATABASE" ] ; then
  echo "# create_db"
  create_opts="-t create_db --skip-fs-checks -s $VERTICA_HOSTS --database $VERTICA_DATABASE  ${DBPW} -D $VERTICA_DATA -i"
  /opt/vertica/bin/admintools $create_opts
else
  #Start db if exists, and not started 
  start_db=" -t start_db --database $VERTICA_DATABASE ${DBPW} -i"
  /opt/vertica/bin/admintools -t list_db -d $VERTICA_DATABASE \
     && ( /opt/vertica/bin/admintools -t db_status -s down | grep "^${VERTICA_DATABASE}$" ) \
     && /opt/vertica/bin/admintools $start_db
fi

# Start last original entrypoint
if [ -x  /opt/vertica/bin/docker-entrypoint.sh ] ; then
	/opt/vertica/bin/docker-entrypoint.sh
fi
