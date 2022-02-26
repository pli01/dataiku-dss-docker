script-create-db
DEPOT_PATH=$(kubectl exec $POD_NAME -i -- cat /etc/podinfo/local-data-path)/depot
DB_NAME=$(kubectl exec $POD_NAME -i -- cat /etc/podinfo/database-name)
    cat << EOF > /tmp/create.sh
    #!/bin/sh
    set -o xtrace
    set -o errexit
    SU_PASSWD=\$(cat /etc/podinfo/superuser-passwd 2> /dev/null || :)

# 
bash -x /opt/vertica/bin/docker-entrypoint.sh re-ip-vertica-node
# install 
docker exec -it latelier_db_vertica sudo /opt/vertica/sbin/install_vertica  --license /home/dbadmin/licensing/ce/vertica_community_edition.license.key  --accept-eula --hosts 127.0.0.1  --dba-user-password-disabled     --failure-threshold NONE     --no-system-configuration     --point-to-point     --data-dir /home/dbadmin/local-data/data --debug
bash -x /opt/vertica/bin/docker-entrypoint.sh
# create db
docker exec -it latelier_db_vertica /opt/vertica/bin/admintools -t create_db --skip-fs-checks --hosts=127.0.0.1 --database dss -p changeme -D /home/dbadmin/local-data/data/ -l /home/dbadmin/licensing/ce/vertica_community_edition.license.key 

# test
vsql -w changeme -c 'SELECT NODE_NAME, NODE_ADDRESS, NODE_STATE FROM NODES;'  ; echo $?
# agent start

