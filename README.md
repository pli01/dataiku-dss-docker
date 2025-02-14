# Dataiku Data Science Studio multi node docker-compose

[![CI](https://github.com/pli01/dataiku-dss-docker/actions/workflows/main.yml/badge.svg)](https://github.com/pli01/dataiku-dss-docker/actions/workflows/main.yml)

## Description
This docker-compose stack includes the following Dataiku Data Science Studio (DSS) services
* `design` node (default)
* `automation` node
* `apideployer` node
* `api` node
* `dkumonitor` node: Graphite/Grafana stack (optional)
* database examples: mysql, postgresql, vertica, mongodb


![Architecture](./docs/dataiku-dss-docker-stack.png)

Added Features:
* Add extended centos based official docker dataiku/dss
* Add custom debian docker image based on official dataiku requirements and usefull addons
* Add DSS_INSTALL_ARGS variables in docker entrypoint (run.sh) to configure:
  + install node type (-t option for installer.sh)
  + INSTALL_SIZE per services (big, medium, small)
  + license path per services
* auto register dss nodes in dkumonitor
* install python pip requirements for offline install at runtime (default: python2.7)
* install jdbc driver (vertica,mysql)
* add docker container engine support
* provide sample db (vertica,mysql) to test connections

Sources:
* [official docker hub image dataiku/dss](https://hub.docker.com/r/dataiku/dss/)
* [official github dataiku/dss](https://github.com/dataiku/dataiku-tools/tree/master/dss-docker)
* [requirements for debian](https://doc.dataiku.com/dss/latest/installation/custom/initial-install.html#debian-ubuntu-linux-distributions)
* [dkumonitor](https://github.com/dataiku/dkumonitor)

## Versions
(From `Makefile.mk`)
| Package | Version | Comment | 
| --- | --- | --- |
| dataiku/dss | 8.0.2 | official docker dss is 8.0.2 |
| debian dataiku/dss | 9.0.4 | debian docker dataiku/dss support from 8.0.2 and last version 9.0.4 |
| dkumonitor| 0.0.5  | |
| jdbc vertica | 10.1.1-0 | |
| jdbc mysql | 8.0.24 | |
| mysql | 8.0.24 | |
| postgres | 12.6 | |

Notes:
 * api node need specific license
 * dataiku services are running on following port (You can override it in artifacts file)
   - 10000 (design)
   - 10001 (automation)
   - 10002 (apideployer)
   - 10003 (api)
 * dkumonitor services are running on following ports:
   - 27600 (graphana) # UI
   - 27601 (carbon tcp/udp) # DSS monitoring integration port / API nodes QPS for API Deployer
   - 27602 (carbonapi_http) # APIdeployer monitoring
   - following ports below doesn t need to be exposed
   - 27603 (carbon_carbonserver_port)
   - 27604 (carbon_pickle_port)
   - 27605 (carbon_protobuf_port)
   - 27606 (carbon_http_port)
   - 27607 (carbon_link_port)
   - 27608 (carbon_grpc_port)
   - 27609 (carbon_tags_port)
 * docker version:
   - dataiku/dss:8.0.2
   - official dataiku archive is 8.0.7 and 9.0.4

## Usage

### customization

* (opt) create `artifacts` to override default `Makefile.mk` value (ex: COMPOSE_PROJECT_NAME, DESIGN_PORT,...)
* (opt) create `docker-compose-custom.yml` to override default value (ex: license path file) (see sample)
* (opt) create `docker-compose-custom-db-XXX.yml` to override default value of `docker-compose-db-XXX.yml`

### Prereq: Build custom dss image
Images are named `dataiku_dss` and `dataiku_dkumonitor`

2 options:
* step build a custom docker image based on official dataiku/dss image.
* step build a custom docker image based debian and official dataiku requirements

| Description |  command |
| --- | --- |
| build the extended centos based official docker dataiku/dss (8.0.2) | `make build` |
| build a debian customized dataiku/dss | `make build-debian` |
| build dkumonitor | `make build-dkumonitor` |

### start all services (design,automation,api,apideployer,dkumonitor)
| Description |  command |
| --- | --- |
| start all nodes | `make up` |
| stop all nodes | `make down` |

### start only one service
| Description |  command |
| --- | --- |
| start design node | `make up-design` |
| stop design node | `make down-design` |
| start automation node | `make up-automation` |
| stop automation node | `make down-automation` |
| start apideployer node | `make up-apideployer` |
| stop apideployer node | `make down-apideployer` |
| start api node | `make up-api` |
| stop api node | `make down-api` |
| start dkumonitor node | `make up-dkumonitor` |
| stop dkumonitor node | `make down-dkumonitor` |
| --- | --- |
| start mysql node | `make up-db-mysql` |
| stop mysql node | `make down-db-mysql` |
| start postgres node | `make up-db-postgres` |
| stop postgres node | `make down-db-postgres` |


### test service is running
| Description |  command |
| --- | --- |
| test all services | `make test-all` |
| test only one service (ex: design) | `make test-design` |

## Warning: to clean/erase data dir
| Description |  command |
| --- | --- |
| clean/erase all data services | `make clean-data-dir` |
| clean/erase only one data service (ex: design)| `make clean-data-dir-design` |
