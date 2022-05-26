# elasticms-docker ![Continuous Docker Image Build](https://github.com/ems-project/elasticms-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

ElasticMS in Docker containers

## Prerequisite
Before launching the bats commands you must defined the following environment variables:
```dotenv
ELASTICMS_ADMIN_VERSION=1.14.15 #the elasticms's version you want to test
ELASTICMS_ADMIN_DOCKER_IMAGE_NAME=docker.io/elasticms/admin # The ElasticMS Docker image name  
```
You must also install `bats`.

# Build

```sh
docker build --build-arg VERSION_ARG=${ELASTICMS_ADMIN_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG=snapshot \
             --build-arg VCS_REF_ARG=snapshot \
             --build-arg GITHUB_TOKEN_ARG=${GITHUB_TOKEN} \
             --tag ${ELASTICMS_ADMIN_DOCKER_IMAGE_NAME}:rc .
```

# Test

```sh
bats test/tests.bats
```

# Environment variables  

## CLI_PHP_MEMORY_LIMIT
Refers to the PHP memory limit of the Symfony CLI. This variable can be defined per project or globally for all projects. Or even defined globally and overridden per project. To define it globally use regular environment mechanisms, such -e attribute in docker command. To defnie it per projet, define this variable in the project's Dotenv file. The default value is set to '512M'. Mor information about the [php_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) directive.

## JOBS_ENABLED
Use Supervisord for ems jobs running (ems:job:run).

## JOBS_OPTS
Add parameters to ems:job:run command.

# PUID
Define the user identifier. Default value `1001`.


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