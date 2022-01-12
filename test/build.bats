#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_ELASTICMS_ADMIN_VERSION=${ELASTICMS_ADMIN_VERSION:-1.17.10}
export BATS_RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BATS_BUILD_DATE=${BUILD_DATE:-snapshot}
export BATS_VCS_REF=${VCS_REF:-snapshot}

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_ELASTICMS_ADMIN_DOCKER_IMAGE_NAME="${ELASTICMS_ADMIN_DOCKER_IMAGE_NAME:-docker.io/elasticms/admin:rc}"

docker-compose -f docker-compose-fs.yml build --compress --pull elasticms >&2

@test "[$TEST_FILE] Check Elasticms Docker images build" {
  run docker inspect --type=image ${BATS_ELASTICMS_ADMIN_DOCKER_IMAGE_NAME}
  [ "$status" -eq 0 ]
}
