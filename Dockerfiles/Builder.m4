ENV ELASTICMS_VERSION=${VERSION_ARG:-5.1.2} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms-admin/archive"

RUN echo "Download and install ElastiCMS ..." \
    && mkdir -p /opt/src \
    && curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /opt/src --strip-components=1 \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv install --no-interaction --no-suggest --no-scripts --working-dir /opt/src -o  \
    && rm -rf /opt/src/bootstrap/cache/* /opt/src/.env /opt/src/.env.dist