FROM docker.io/alpine:3.9

ARG ELASTICMS_VERSION_ARG=""
ARG ELASTICMS_DOCKER_RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

USER root

ENV ELASTICMS_VERSION=${ELASTICMS_VERSION_ARG}                                                                                     \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms/archive"                                                      \
    COMPOSER_INSTALLER_SHA384SUM=""                                                                                                \
    MAIL_SMTP_SERVER=""                                                                                                            \
    MAIL_FROM_DOMAIN=""                                                                                                            \
    PHP_FPM_MAX_CHILDREN=${PHP_FPM_MAX_CHILDREN:-5}                                                                                \
    PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES=${PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-64}                                         \
    CONTAINER_HEAP_PERCENT=${CONTAINER_HEAP_PERCENT:-0.80}                                                                         \
    HOME=/opt                                                                                                                      \
    PATH=/opt/bin:/usr/local/bin:/usr/bin:$PATH

LABEL org.label-schema.build-date=$BUILD_DATE_ARG \
      org.label-schema.name="ElasticMS - PHP Docker Image." \
      org.label-schema.description="A minimal CMS to manage generic content in order to publish it in several Elasticsearch index (based on Symfony 3)." \
      org.label-schema.url="http://www.elasticms.eu" \
      org.label-schema.vcs-ref=$VCS_REF_ARG \
      org.label-schema.vcs-url="https://github.com/ems-project/elasticms" \
      org.label-schema.vendor="sebastian.molle@gmail.com" \
      org.label-schema.version="$ELASTICMS_VERSION_ARG-$ELASTICMS_DOCKER_RELEASE_ARG" \
      org.label-schema.schema-version="1.0"

WORKDIR ${HOME}

COPY etc/php7 /etc/php7
COPY etc/ssmtp /etc/ssmtp
COPY bin/apk-list /usr/local/bin/apk-list
COPY bin/usage /usr/local/bin/usage
COPY bin/container-entrypoint-php /usr/local/bin/container-entrypoint
COPY bin/dynamic_resources /usr/local/bin/dynamic_resources
COPY bin/func_fill_in_template_file_using_env /usr/local/bin/func_fill_in_template_file_using_env
COPY bin/run-php /usr/local/bin/run-php

RUN echo "Install Alpine packages ..."                                                                                          && \
    apk --update add curl tzdata bash tar gettext ssmtp mailx coreutils php7-intl php7-openssl php7-dba php7-sqlite3 php7-pear     \
                     php7-phpdbg php7-litespeed php7-gmp php7-pdo_mysql php7-pcntl php7-common php7-xsl php7-mysqlnd php7-enchant  \
                     php7-pspell php7-snmp php7-doc php7-mbstring php7-xmlrpc php7-embed php7-xmlreader php7-pdo_sqlite            \
                     php7-exif php7-opcache php7-ldap php7-posix php7-session php7-gd php7-gettext php7-json                       \
                     php7-xml php7 php7-iconv php7-sysvshm php7-curl php7-shmop php7-odbc php7-phar php7-imap                      \
                     php7-pdo_pgsql php7-pdo_dblib php7-pgsql php7-pdo_odbc php7-zip php7-ctype php7-mcrypt                        \
                     php7-wddx php7-bcmath php7-calendar php7-tidy php7-dom php7-sockets php7-soap php7-apcu                       \
                     php7-sysvmsg php7-zlib php7-ftp php7-sysvsem php7-pdo php7-bz2 php7-mysqli php7-fileinfo mysql-client         \
                     php7-simplexml php7-tokenizer php7-xmlwriter php7-fpm postgresql-client postgresql                         && \
    echo "Setup timezone ..."                                                                                                   && \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime                                                                       && \
    echo "Europe/Brussels" > /etc/timezone                                                                                      && \
    echo "Cleanup Alpine packages ..."                                                                                          && \
    rm -rf /var/cache/apk/*                                                                                                     && \
    echo "Add non-privileged user ..."                                                                                          && \
    adduser -D -u 1001 -g default -s /sbin/nologin default                                                                      && \
    echo "Download and install Composer ..."                                                                                    && \
    curl -sSfLk https://getcomposer.org/installer -o /tmp/composer-setup.php                                                    && \
    curl -sSfLk https://composer.github.io/installer.sig -o /tmp/composer-setup.sig                                             && \
    COMPOSER_INSTALLER_SHA384SUM=$(cat /tmp/composer-setup.sig)                                                                 && \
    echo "$COMPOSER_INSTALLER_SHA384SUM /tmp/composer-setup.php" | sha384sum -c                                                 && \
    php /tmp/composer-setup.php --disable-tls --install-dir=/usr/local/bin                                                      && \
    rm /tmp/composer-setup.php /tmp/composer-setup.sig                                                                          && \
    ln -s /usr/local/bin/composer.phar /usr/local/bin/composer                                                                  && \
    chmod +x /usr/local/bin/composer.phar /usr/local/bin/composer                                                               && \
    mkdir /home/default/.composer                                                                                               && \
    echo "Download and install elasticms ..."                                                                                   && \
    mkdir -p /opt/src                                                                                                           && \
    curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz                                                            | \
    tar -xzC /opt/src --strip-components=1                                                                                      && \
    composer -vvvv install --no-interaction --no-suggest --working-dir /opt/src -o                                              && \
    rm -rf /opt/src/bootstrap/cache/* /opt/src/.env /opt/src/.env.dist                                                          && \
    echo "Setup permissions on filesystem for non-privileged user ..."                                                          && \
    mkdir -p /opt/bin /opt/src /opt/etc /var/log/php-fpm /var/run/php-fpm /var/php/session /var/php/wsdlcache                   && \
    chown -Rf 1001:0 /opt /etc/ssmtp /etc/php7 /var/log/php-fpm /var/run/php-fpm /var/php/session /var/php/wsdlcache            && \
    chmod -R ug+rw /opt /etc/ssmtp /etc/php7 /var/log/php-fpm /var/run/php-fpm /var/php/session /var/php/wsdlcache              && \
    find /etc/ssmtp -type d -exec chmod ug+x {} \;                                                                              && \
    find /opt -type d -exec chmod ug+x {} \;                                                                                    && \
    find /etc/php7 -type d -exec chmod ug+x {} \;                                                                               && \
    chmod +x /usr/local/bin/apk-list                                                                                               \
             /usr/local/bin/container-entrypoint                                                                                   \
             /usr/local/bin/run-php                                                                                                \
             /usr/local/bin/usage                                                                                               && \
    ln -s /etc/php7 /etc/php                                                                                                    && \
    touch /var/log/php-fpm/fpm-error.log                                                                                        && \
    touch /var/log/php-fpm/fpm-access.log                                                                                       && \
    ln -sf /dev/stdout /var/log/php-fpm/fpm-access.log                                                                          && \
    ln -sf /dev/stderr /var/log/php-fpm/fpm-error.log

USER 1001

VOLUME ["/var/run/php-fpm","/opt/src"]

ENTRYPOINT ["container-entrypoint"]

CMD ["run-php"]
