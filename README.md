# elasticms-docker [![Build Status](https://travis-ci.org/ems-project/elasticms-docker.svg?branch=master)](https://travis-ci.org/ems-project/elasticms-docker)

## Prerequisite
Before launching the bats commands you must defined the following environment variables:
```dotenv
ELASTICMS_VERSION=1.14.15 #the elasticms's version you want to test
```
You must also install `bats`.

## Commands
 - `bats test/build.bats` : builds the docker image
 - `bats test/tests.fs.storage.bats` : tests the image with a file system storage
 - `bats test/tests.s3.storage.bats` : tests the image with a s3 storage
 - `bats test/scan.bats` : scan the image with [Clair Scanner](https://github.com/arminc/clair-scanner)
 

ElasticMS in Docker containers

# Environment variables
## CLI_PHP_MEMORY_LIMIT
Refers to the PHP memory limit of the Symfony CLI. This variable can be defined per project or globally for all projects. Or even defined globally and overridden per project. To define it globally use regular environment mechanisms, such -e attribute in docker command. To defnie it per projet, define this variable in the project's Dotenv file. The default value is set to '512M'. Mor information about the [php_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) directive.

# JOBS_ENABLED
Use Supervisord for ems jobs running (ems:job:run).

# JOBS_OPTS
Add parameters to ems:job:run command.


# Magick command to remove all
```docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)```

Caution, it removes every running pods.

If you want to also remove all persisted data in your docker environment:
`docker volume rm $(docker volume ls -q)`

# Development
Compress a dump:
`cd test/dumps/ && tar -zcvf example.tar.gz example.dump && cd -`