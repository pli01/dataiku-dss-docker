##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

EDITOR=vim
SHELL = /bin/bash

include /etc/os-release

COMPOSE_PROJECT_NAME ?= latelier
DSS_VERSION ?= 8.0.2
#
# NODETYPE=design automation api apideployer
# INSTALL_SIZE=auto big medium small
INSTALL_SIZE ?= auto
DSS_INSTALLER_ARGS ?= # -l /home/dataiku/license.json
#
DESIGN_NODETYPE           = design
DESIGN_DATA_DIR           ?= ./data-design
DESIGN_PORT               ?=10000
DESIGN_INSTALL_SIZE       ?= ${INSTALL_SIZE}
DESIGN_DSS_INSTALLER_ARGS ?= -t ${DESIGN_NODETYPE} ${DSS_INSTALLER_ARGS} -s ${DESIGN_INSTALL_SIZE}
#
AUTOMATION_NODETYPE           = automation
AUTOMATION_DATA_DIR           ?= ./data-automation
AUTOMATION_PORT               ?= 10001
AUTOMATION_INSTALL_SIZE       ?= ${INSTALL_SIZE}
AUTOMATION_DSS_INSTALLER_ARGS ?= -t ${AUTOMATION_NODETYPE} ${DSS_INSTALLER_ARGS} -s ${AUTOMATION_INSTALL_SIZE}
#
API_NODETYPE           = api
API_DATA_DIR           ?= ./data-api
API_PORT               ?=10002
API_INSTALL_SIZE       ?= ${INSTALL_SIZE}
API_DSS_INSTALLER_ARGS ?= -t ${API_NODETYPE} ${DSS_INSTALLER_ARGS} -s ${API_INSTALL_SIZE}
#
APIDEPLOYER_NODETYPE           = apideployer
APIDEPLOYER_DATA_DIR           ?= ./data-apideployer
APIDEPLOYER_PORT               ?= 10003
APIDEPLOYER_INSTALL_SIZE       ?= ${INSTALL_SIZE}
APIDEPLOYER_DSS_INSTALLER_ARGS ?= -t ${APIDEPLOYER_NODETYPE} ${DSS_INSTALLER_ARGS} -s ${APIDEPLOYER_INSTALL_SIZE}

dummy               := $(shell touch artifacts)
include ./artifacts
export

install-prerequisites:
ifeq ("$(wildcard /usr/bin/docker)","")
        @echo install docker-ce, still to be tested
        sudo apt-get update
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

vertica:
ifeq ("$(wildcard data/lib/jdbc/vertica-jdbc-9.0.1-0.jar)","")
	@sudo cp jdbc/vertica-jdbc-9.0.1-0.jar data/lib/jdbc/
endif

network: 
	@docker network create latelier 2> /dev/null; true

requirements: up
	docker exec -it dss /home/dataiku/dss/bin/pip install --proxy ${http_proxy} -r requirements.txt

# create data dir if not exist
pre-up: pre-up-design pre-up-automation pre-up-api pre-up-apideployer
pre-up-design:
	echo "# pre up design"
	if [ ! -d "${DESIGN_DATA_DIR}" ] ; then mkdir -p ${DESIGN_DATA_DIR} ; chown $(shell id -un). ${DESIGN_DATA_DIR} ; fi
pre-up-automation:
	echo "# pre up automation"
	if [ ! -d "${AUTOMATION_DATA_DIR}" ] ; then mkdir -p ${AUTOMATION_DATA_DIR} ; chown $(shell id -un). ${AUTOMATION_DATA_DIR} ; fi
pre-up-api:
	echo "# pre up api"
	if [ ! -d "${API_DATA_DIR}" ] ; then mkdir -p ${API_DATA_DIR} ; chown $(shell id -un). ${API_DATA_DIR} ; fi
pre-up-apideployer:
	echo "# pre up apideployer"
	if [ ! -d "${APIDEPLOYER_DATA_DIR}" ] ; then mkdir -p ${APIDEPLOYER_DATA_DIR} ; chown $(shell id -un). ${APIDEPLOYER_DATA_DIR} ; fi

# clean data dir if exist
clean-data-dir: clean-data-dir-design clean-data-dir-automation clean-data-dir-api clean-data-dir-apideployer
clean-data-dir-design:
	if [ -d "${DESIGN_DATA_DIR}" ] ; then rm -rf ${DESIGN_DATA_DIR} ; fi
clean-data-dir-automation:
	if [ -d "${AUTOMATION_DATA_DIR}" ] ; then rm -rf ${AUTOMATION_DATA_DIR} ; fi
clean-data-dir-api:
	if [ -d "${API_DATA_DIR}" ] ; then rm -rf ${API_DATA_DIR} ; fi
clean-data-dir-apideployer:
	if [ -d "${APIDEPLOYER_DATA_DIR}" ] ; then rm -rf ${APIDEPLOYER_DATA_DIR} ; fi

# build custome dss image with custom args installer
build:
	docker-compose -f docker-compose.yml  build --force-rm --no-cache build_dss

# default start all services
up: pre-up up-all

up-all:
ifeq ("$(wildcard docker-compose-custom.yml)","")
	docker-compose up  --no-build -d
else
	docker-compose -f docker-compose.yml -f docker-compose-custom.yml up --no-build -d
endif
#	docker exec -u root -it ${COMPOSE_PROJECT_NAME}_dss apt-get update
#	docker exec -u root -it ${COMPOSE_PROJECT_NAME}_dss apt-get install -y gnupg

down:
	docker-compose down

restart: down up

# manage only one service (design,automation,api,apideployer)
up-%: | pre-up-%
ifeq ("$(wildcard docker-compose-custom.yml)","")
	docker-compose up  --no-build -d $*
else
	docker-compose -f docker-compose.yml -f docker-compose-custom.yml up --no-build -d $*
endif

stop-%:
ifeq ("$(wildcard docker-compose-custom.yml)","")
	docker-compose stop $*
else
	docker-compose -f docker-compose.yml -f docker-compose-custom.yml stop $*
endif
rm-%:
ifeq ("$(wildcard docker-compose-custom.yml)","")
	docker-compose rm  $*
else
	docker-compose -f docker-compose.yml -f docker-compose-custom.yml rm -s -f $*
endif

down-%: | stop-% rm-%
	@echo "# down $*"
