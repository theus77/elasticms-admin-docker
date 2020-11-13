FROM docker.io/elasticms/base-php-dev:7.4 as builder

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

ENV ELASTICMS_VERSION=${VERSION_ARG:-1.9.55} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms/archive" 

RUN echo "Download and install ElastiCMS ..." \
    && mkdir -p /opt/src \
    && curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /opt/src --strip-components=1 \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv install --no-interaction --no-suggest --no-scripts --working-dir /opt/src -o  \
    && rm -rf /opt/src/bootstrap/cache/* /opt/src/.env /opt/src/.env.dist 

FROM docker.io/elasticms/base-php-apache:7.4

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL eu.elasticms.admin.build-date=$BUILD_DATE_ARG \
      eu.elasticms.admin.name="ElasticMS - Admin." \
      eu.elasticms.admin.description="A minimal CMS to manage generic content in order to publish it in several Elasticsearch index." \
      eu.elasticms.admin.url="https://www.elasticms.eu/" \
      eu.elasticms.admin.vcs-ref=$VCS_REF_ARG \
      eu.elasticms.admin.vcs-url="https://github.com/ems-project/elasticms" \
      eu.elasticms.admin.vendor="sebastian.molle@gmail.com" \
      eu.elasticms.admin.version="$VERSION_ARG" \
      eu.elasticms.admin.release="$RELEASE_ARG" \
      eu.elasticms.admin.schema-version="1.0" \
      eu.elasticms.admin.docker-image="all-in-one"

USER root

COPY bin/ /opt/bin/
COPY etc/ /usr/local/etc/

COPY --from=builder /opt/src /opt/src

RUN echo "Setup permissions on filesystem for non-privileged user ..." \
    && mkdir -p /var/lib/ems \
    && chmod -Rf +x /opt/bin /var/lib/ems \ 
    && chown -Rf 1001:0 /opt /var/lib/ems \
    && chmod -R ug+rw /opt /var/lib/ems \
    && find /opt -type d -exec chmod ug+x {} \; 

USER 1001

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1
