#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export ELASTICMS_VERSION=${ELASTICMS_VERSION:-1.9.55}
export RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BUILD_DATE=${BUILD_DATE:-snapshot}
export VCS_REF=${VCS_REF:-snapshot}

export BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME=${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME:-clair_local_scanner}
export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_EMS_DOCKER_IMAGE_NAME="${EMS_DOCKER_IMAGE_NAME:-docker.io/elasticms/elasticms}:rc"

@test "[$TEST_FILE] Starting Elasticms Docker images build" {
  command docker-compose -f docker-compose-fs.yml build --no-cache elasticms 
}
