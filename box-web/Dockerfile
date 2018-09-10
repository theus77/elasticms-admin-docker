FROM docker.io/alpine:3.8

ARG ELASTICMS_VERSION_ARG=""

USER root

ENV ELASTICMS_VERSION=${ELASTICMS_VERSION_ARG}                                                                                     \
    HOME=/opt

LABEL MAINTAINER="sebastian.molle@gmail.com"                                                                                       \
      application.name="elasticms"                                                                                                 \
      application.component="apache"                                                                                               \
      io.k8s.description="Platform for running Apache Webserver"                                                                   \
      io.k8s.display-name="Apache"                                                                                                 \
      io.openshift.tags="apache httpd"                                                                                             \
      application.version=${ELASTICMS_VERSION}

WORKDIR ${HOME}

COPY etc/apache2 /etc/apache2
COPY bin/apk-list /usr/local/bin/apk-list
COPY bin/usage /usr/local/bin/usage
COPY bin/container-entrypoint-web /usr/local/bin/container-entrypoint
COPY bin/dynamic_resources /usr/local/bin/dynamic_resources
COPY bin/func_fill_in_template_file_using_env /usr/local/bin/func_fill_in_template_file_using_env
COPY bin/run-web /usr/local/bin/run-web

COPY src/ /opt/src

RUN apk add --update tzdata bash coreutils apache2 apache2-utils apache2-proxy                                                  && \
    echo "Setup timezone ..."                                                                                                   && \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime                                                                       && \
    echo "Europe/Brussels" > /etc/timezone                                                                                      && \
    echo "Cleanup Alpine packages ..."                                                                                          && \
    apk del tzdata                                                                                                              && \
    rm -rf /var/cache/apk/*                                                                                                     && \
    echo "Add non-privileged user ..."                                                                                          && \
    adduser -D -u 1001 -g default -s /sbin/nologin default                                                                      && \
    echo "Setup permissions on filesystem for non-privileged user ..."                                                          && \
    mkdir -p /run/apache2 /var/run/apache2 /var/log/apache2 /opt/src                                                            && \
    chown -R 1001:0 /run/apache2 /var/run/apache2 /var/log/apache2 /opt/src /etc/apache2                                        && \
    chmod -R a+rwx /run/apache2 /var/run/apache2 /var/log/apache2 /opt/src                                                      && \
    chmod +x /usr/local/bin/apk-list                                                                                               \
             /usr/local/bin/container-entrypoint                                                                                   \
             /usr/local/bin/run-web                                                                                                \
             /usr/local/bin/usage                                                                                               && \
    chown 1001:0 -Rf /etc/apache2                                                                                               && \
    chmod -R ug+rw /etc/apache2                                                                                                 && \
    find /etc/apache2 -type d -exec chmod ug+x {} \;                                                                            && \
    touch /var/log/apache2/error.log                                                                                            && \
    touch /var/log/apache2/access.log                                                                                           && \
    ln -sf /dev/stdout /var/log/apache2/access.log                                                                              && \
    ln -sf /dev/stderr /var/log/apache2/error.log

USER 1001

ENTRYPOINT ["container-entrypoint"]

EXPOSE 8080

CMD ["usage"]
