ARG DSS_VERSION
FROM dataiku/dss:${DSS_VERSION:-8.0.2}
# add DSS_INSTALLER_ARGS dss entrypoint run.sh
ENV DSS_INSTALLER_ARGS $DSS_INSTALLER_ARGS
# Add dkumonitor
ENV GRAPHITE_HOST=$GRAPHITE_HOST \
    GRAPHITE_PORT=$GRAPHITE_PORT

# Add vertica
ARG VERTICA_VERSION=${VERTICA_VERSION:-10.1.1-0}
ENV VERTICA_VERSION=${VERTICA_VERSION}
# Add mysql
ARG MYSQL_VERSION=${MYSQL_VERSION:-8.0.24}
ENV MYSQL_VERSION=${MYSQL_VERSION}

# Add python requirements
ARG PYPI_URL
ARG PYPI_HOST

USER root
COPY build.sh .
COPY postinstall.sh .
COPY requirements.txt .
RUN set -e ; bash build.sh && rm -rf build.sh

USER dataiku
# Add monitoring
RUN dataiku-dss-$DSS_VERSION/scripts/install/download-monitoring-packages.sh
