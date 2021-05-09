#!/bin/bash
set -x
echo $(basename $0)
sleep 5
echo "# install_vertica"
sudo /opt/vertica/sbin/install_vertica --debug -s 127.0.0.1 -L CE -Y --dba-user-password changeme --failure-threshold NONE --no-system-configuration --point-to-point -d /home/dbadmin/local-data/data
chown $USER. /opt/vertica/config/admintools.conf
echo "# create_db"
/opt/vertica/bin/admintools -t create_db --skip-fs-checks -s 127.0.0.1 --database dss -p changeme -D /home/dbadmin/local-data/data/
#echo "# stop_db"
#/opt/vertica/bin/admintools -t stop_db --database dss -p changeme
#/opt/vertica/bin/admintools -t start_db --database dss
#/opt/vertica/bin/admintools -t db_status -s ALL
