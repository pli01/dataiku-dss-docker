##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

EDITOR=vim

include /etc/os-release

export PORT=10000
export COMPOSE_PROJECT_NAME=latelier

dummy               := $(shell touch artifacts)
include ./artifacts

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

up: network
ifeq ("$(wildcard docker-compose-custom.yml)","")
	docker-compose up -d
else
	docker-compose -f docker-compose.yml -f docker-compose-custom.yml up -d
endif
	docker exec -u root -it ${COMPOSE_PROJECT_NAME}_dss apt-get update
	docker exec -u root -it ${COMPOSE_PROJECT_NAME}_dss apt-get install -y gnupg

down:
	docker-compose down

restart: down up

