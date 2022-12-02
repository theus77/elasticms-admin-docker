# elasticms-admin-docker ![Continuous Docker Image Build](https://github.com/ems-project/elasticms-admin-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

ElasticMS in Docker containers

## Prerequisite
Before launching the bats commands you must defined the following environment variables:
```dotenv
ELASTICMS_ADMIN_VERSION=1.14.15 #the elasticms's version you want to test
DOCKER_IMAGE_NAME=docker.io/elasticms/admin:rc # The ElasticMS Docker image name  
```
You must also install `bats`.

# Build

```sh
docker build --build-arg VERSION_ARG=${ELASTICMS_ADMIN_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG=snapshot \
             --build-arg VCS_REF_ARG=snapshot \
             --build-arg GITHUB_TOKEN_ARG=${GITHUB_TOKEN} \
             --tag ${DOCKER_IMAGE_NAME} .
```

# Test

```sh
bats test/tests.bats
```

# Environment variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| CLI_PHP_MEMORY_LIMIT | Refers to the PHP memory limit of the Symfony CLI. This variable can be defined per project or globally for all projects. Or even defined globally and overridden per project. To define it globally use regular environment mechanisms, such -e attribute in docker command. To defnie it per projet, define this variable in the project's Dotenv file. More information about the [php_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) directive.  | `512M` | `2048M` |
| JOBS_ENABLED | Use Supervisord for ems jobs running (ems:job:run). | N/A | `true` |
| JOBS_OPTS | Add parameters to ems:job:run command.  | N/A | `-v` |
| CHECK_ALIAS_OPTS | Add parameters to ems:check:aliases command.  | `-repair` | `-repair -v` |
| PUID | Define the user identifier  | `1001` | `1000` |
| APACHE_CUSTOM_ASSETS_RC | Rewrite condition that prevent request to be treated by PHP, typically bundles or assets | `^\"+.alias+\"/bundles` | `/bundles/` |
| APACHE_X_FRAME_OPTIONS | The X-Frame-Options HTTP response header can be used to indicate whether or not a browser should be allowed to render a page in a <frame>, <iframe>, <embed> or <object>. | `SAMEORIGIN` | `DENY` |
| APACHE_X_XSS_PROTECTION | The HTTP X-XSS-Protection response header is a feature of Internet Explorer, Chrome and Safari that stops pages from loading when they detect reflected cross-site scripting (XSS) attacks. | `1` | `1; mode=block`, `0` |
| APACHE_X_CONTENT_TYPE_OPTIONS | The X-Content-Type-Options response HTTP header is a marker used by the server to indicate that the MIME types advertised in the Content-Type headers should be followed and not be changed. | `nosniff` | `` |



## METRIC_ENABLED
Return ElasticMS Prometheus metrics.  

| Variable Name | Description | Default |
| - | - | - |
| METRICS_ENABLED | Add metrics dedicated vhost running on a specific port (9090). | `empty` |
| METRICS_VHOST_SERVER_NAME_CUSTOM | Apache ServerName directive used for dedicated vhost. | `$(hostname -i)` |

# Magick command to remove all
```docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)```

Caution, it removes every running containers.

If you want to also remove all persisted data in your docker environment:
`docker volume rm $(docker volume ls -q)`

# Development
Compress a dump:
`cd test/dumps/ && tar -zcvf example.tar.gz example.dump && cd -`