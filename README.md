# elasticms-admin-docker [![Docker Build](https://github.com/ems-project/elasticms-admin-docker/actions/workflows/docker-build.yml/badge.svg?branch=5.x)](https://github.com/ems-project/elasticms-admin-docker/actions/workflows/docker-build.yml) 

ElasticMS in Docker containers

## Prerequisite

You must install `bats`, `make`.

# Build

```sh
make build[-dev|-all] ELASTICMS_ADMIN_VERSION=<ElasticMS Admin Version you want to build> [ DOCKER_IMAGE_NAME=<ElasticMS Admin Docker Image Name you want to build> ]
```

## Example building __prd__ Docker image

```sh
make build ELASTICMS_ADMIN_VERSION=5.1.2
```

__Provide docker image__ : `docker.io/elasticms/admin:5.1.2-prd`

## Example building __dev__ Docker image

```sh
make build-dev ELASTICMS_ADMIN_VERSION=5.1.2
```

__Provide docker image__ : `docker.io/elasticms/admin:5.1.2-dev`

# Test

```sh
make test[-dev|-all] ELASTICMS_ADMIN_VERSION=<ElasticMS Admin Version you want to test>
```

## Example testing of __prd__ builded docker image

```sh
make test ELASTICMS_ADMIN_VERSION=5.1.2
```

## Example testing of __dev__ builded docker image

```sh
make test-dev ELASTICMS_ADMIN_VERSION=5.1.2
```

# Releases

Releases are done via GitHub actions and uploaded on Docker Hub.

# Supported tags and respective Dockerfile links

- [`5.x.y`, `5.x`, `5`, `5.x.y-prd`, `5.x-prd`, `5-prd`, `5.x.y-dev`, `5.x-dev`, `5-dev`](Dockerfile)

# Image Variants

The elasticms/admin images come in many flavors, each designed for a specific use case.

## `docker.io/elasticms/admin:<version>[-prd]`  

This variant contains the [ElasticMS Admin](https://github.com/ems-project/elasticms-admin) installed in a Production PHP environment.  

## `docker.io/elasticms/admin:<version>-dev`

This variant contains the [ElasticMS Admin](https://github.com/ems-project/elasticms-admin) installed in a Development PHP environment.  

# Configuration

## Environment variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| CLI_PHP_MEMORY_LIMIT | Refers to the PHP memory limit of the Symfony CLI. This variable can be defined per project or globally for all projects. Or even defined globally and overridden per project. To define it globally use regular environment mechanisms, such -e attribute in docker command. To defnie it per projet, define this variable in the project's Dotenv file. More information about the [php_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) directive.  | `512M` | `2048M` |
| JOBS_ENABLED | Use Supervisord for ems jobs running (ems:job:run). | N/A | `true` |
| JOBS_OPTS | Add parameters to ems:job:run command.  | N/A | `-v` |
| CHECK_ALIAS_OPTS | Add parameters to ems:check:aliases command.  | `-repair` | `-repair -v` |
| PUID | Define the user identifier  | `1001` | `1000` |
| APACHE_CUSTOM_ASSETS_RC | Rewrite condition that prevent request to be treated by PHP, typically bundles or assets | `^\"+.alias+\"/bundles` | `/bundles/` |
| APACHE_X_FRAME_OPTIONS | The X-Frame-Options HTTP response header can be used to indicate whether or not a browser should be allowed to render a page in a `<frame>`, `<iframe>`, `<embed>` or `<object>`. | `SAMEORIGIN` | `DENY` |
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