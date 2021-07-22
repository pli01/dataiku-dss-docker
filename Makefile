##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

# default values
include Makefile.mk

# override default values
dummy               := $(shell touch artifacts)
include ./artifacts

export

install-prerequisites:
ifeq ($(UNAME),Linux)
ifeq ("$(wildcard /usr/bin/docker)","")
	@echo install docker-ce, still to be tested
	sudo apt-get update ; \
        sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
	curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -
	sudo add-apt-repository \
                "deb https://download.docker.com/linux/ubuntu \
                `lsb_release -cs` \
                stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce
	sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
endif
endif



# build custom dss image with custom args installer
build-all: build build-dkumonitor
build:
	docker-compose ${DC_DSS_BUILD_CONF} build --force-rm --no-cache dss
build-debian:
	docker-compose ${DC_DSS_BUILD_CONF} build --force-rm --no-cache dss_debian
build-dkumonitor:
	docker-compose ${DC_DSS_BUILD_CONF} build --force-rm --no-cache dkumonitor

registry-login:
	@if [ -z "${DOCKER_REGISTRY_TOKEN}" -a -z "${DOCKER_REGISTRY_USERNAME}" ] ; then echo "ERROR: DOCKER_REGISTRY_TOKEN and DOCKER_REGISTRY_USERNAME not defined" ; exit 1 ; fi
	@[ -n "${DOCKER_REGISTRY_TOKEN}" -a -n "${DOCKER_REGISTRY_USERNAME}" ] && echo "${DOCKER_REGISTRY_TOKEN}" | docker login ${DOCKER_REGISTRY} -u ${DOCKER_REGISTRY_USERNAME}  --password-stdin

registry-logout:
	@[ -n "${DOCKER_REGISTRY}" ] && docker logout ${DOCKER_REGISTRY} || true

push-image: registry-login push-image-dss push-image-dkumonitor
push-image-%:
	image_name=$$(docker-compose $(DC_DSS_BUILD_CONF) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin, Loader=yaml.SafeLoader), sys.stdout, indent=4)); print cfg["services"]["$*"]["image"]') ; \
         docker tag $$image_name ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/$$image_name ; \
         docker push ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/$$image_name
# up/down
network:
	@docker network create ${COMPOSE_PROJECT_NAME} 2> /dev/null; true

# default start all services
up: up-all

up-all: pre-up
	docker-compose ${DC_DSS_RUN_CONF} up  --no-build -d

down:
	docker-compose ${DC_DSS_RUN_CONF} down

restart: down up

restart-%: down-% up-%
	echo "# $* restarted"
#
# create data dir if not exist/ clean data dir if exist
#
#
pre-up: pre-up-design pre-up-automation pre-up-api pre-up-apideployer pre-up-dkumonitor

clean-data-dir: clean-data-dir-design clean-data-dir-automation clean-data-dir-api clean-data-dir-apideployer clean-data-dir-dkumonitor
#
# manage db
#
pre-up-db-%: create-data-dir-db-%
	echo "# pre up db $*"
create-data-dir-db-%:
	@if [ ! -d "${$(call UC,$*)_DATADIR}" ] ; then mkdir -p ${$(call UC,$*)_DATADIR} ; chown ${ID_U}:${ID_G} ${$(call UC,$*)_DATADIR} ; fi
clean-data-dir-db-%:
	if [ -d "${$(call UC,$*)_DATADIR}" ] ; then sudo rm -rf ${$(call UC,$*)_DATADIR} ; fi
up-db-%: | pre-up-db-%
	@docker-compose ${DC_DSS_RUN_CONF_DB_$(call UC,$*)} up --no-build -d $*
stop-db-%:
	docker-compose ${DC_DSS_RUN_CONF_DB_$(call UC,$*)} stop $*
rm-db-%:
	docker-compose ${DC_DSS_RUN_CONF_DB_$(call UC,$*)} rm -s -f $*
down-db-%: | stop-db-% rm-db-%
	@echo "# down $*"
restart-db-%: | down-db-% up-db-%
	@echo "# restart db $*"
#
# manage only one service (design,automation,api,apideployer)
#
config:
	docker-compose ${DC_DSS_RUN_CONF} config
pre-up-%: create-data-dir-%
	echo "# pre up $*"
create-data-dir-%:
	if [ ! -d "${$(call UC,$*)_DATADIR}" ] ; then mkdir -p ${$(call UC,$*)_DATADIR} ; chown ${ID_U}:${ID_G} ${$(call UC,$*)_DATADIR} ; fi
clean-data-dir-%:
	if [ -d "${$(call UC,$*)_DATADIR}" ] ; then rm -rf ${$(call UC,$*)_DATADIR} ; fi
up-%: | pre-up-%
	docker-compose ${DC_DSS_RUN_CONF} up  --no-build -d $*
stop-%:
	docker-compose ${DC_DSS_RUN_CONF} stop $*
rm-%:
	docker-compose ${DC_DSS_RUN_CONF} rm -s -f $*
down-%: | stop-% rm-%
	@echo "# down $*"
#
# test
#
test-all: test-design test-automation test-apideployer test-api test-dkumonitor
	@echo "# test all success"
test-%:
	@ci/test-$*.sh

test-up-%:
	@ci/test-up-$*.sh
