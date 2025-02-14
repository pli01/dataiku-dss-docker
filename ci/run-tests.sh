#!/bin/bash
[ -n "$DEBUG" ] && set -x
set -e

#
# test http app
#
function test_app {
  echo "# Test $1 "
  set +e
  ret=0
  timeout=180;
  test_result=1
  until [ "$timeout" -le 0 -o "$test_result" -eq 0 ] ; do
      eval $1
      test_result=$?
      echo "Wait $timeout seconds: APP coming up ($test_result)";
      (( timeout-- ))
      sleep 1
  done
  if [ "$test_result" -gt 0 ] ; then
       ret=$test_result
       echo "ERROR: APP down"
       return $ret
  fi
  set -e

  return $ret
}

echo "# $(basename $0) started"
if [ -n "$DOCKERHUB_LOGIN" -a -n "$DOCKERHUB_TOKEN" ] ; then
  echo "$DOCKERHUB_LOGIN" | docker login --username $DOCKERHUB_TOKEN --password-stdin
fi

echo "# prepare artifacts tests"
cat <<EOF > artifacts
COMPOSE_PROJECT_NAME=ci
DESIGN_DATADIR=data-design
AUTOMATION_DATADIR=data-automation
APIDEPLOYER_DATADIR=data-apideployer
API_DATADIR=data-api
DKUMONITOR_DATADIR=data-dkumonitor
EOF
# ci config
cp docker-compose-ci.yml docker-compose-custom.yml
cp docker-compose-ci-db-mysql.yml docker-compose-custom-db-mysql.yml
cp docker-compose-ci-db-postgres.yml docker-compose-custom-db-postgres.yml

echo "# config"
make config

echo "# clean env"
make down clean-data-dir

echo "# build image"
# make build-all
make build-debian build-dkumonitor

echo "# up all dss services"
make up-all
make test-up-design   
make test-up-dkumonitor

echo "# test all services"
test_app "make test-all"

echo "# clean env"
make down clean-data-dir

echo "# up db service"
make up-db-mysql
make up-db-postgres

echo "# write dss tests"

echo "# clean db service"
make down-db-mysql clean-data-dir-db-mysql
make down-db-postgres clean-data-dir-db-postgres

echo "# clean env"
make down clean-data-dir
if [ -n "$DOCKERHUB_LOGIN" -a -n "$DOCKERHUB_TOKEN" ] ; then
  docker logout
fi
