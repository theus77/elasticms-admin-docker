# elasticms-docker [![Build Status](https://travis-ci.org/ems-project/elasticms-docker.svg?branch=master)](https://travis-ci.org/ems-project/elasticms-docker)

ElasticMS in Docker containers

# Environment variables
## CLI_PHP_MEMORY_LIMIT
Refers to the PHP memory limit of the Symfony CLI. This variable can be defined per project or globally for all projects. Or even defined globally and overridden per project. To define it globally use regular environment mechanisms, such -e attribute in docker command. To defnie it per projet, define this variable in the project's Dotenv file. The default value is set to '512M'. Mor information about the [php_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) directive.

# JOBS_ENABLED
Use Supervisord for ems jobs running (ems:job:run).

# JOBS_OPTS
Add parameters to ems:job:run command.
