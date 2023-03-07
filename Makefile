#!/usr/bin/make -f

ifneq (,$(wildcard ./.build.env))
    include .build.env
    export
endif

GIT_HASH ?= $(shell git log --format="%h" -n 1)
BUILD_DATE ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

# Default ElasticMS Admin version (if no .build.env file provided)
ELASTICMS_ADMIN_VERSION ?= 5.0.0

# Default Docker image name (if no .build.env file provided)
DOCKER_IMAGE_NAME ?= docker.io/elasticms/cli

_BUILD_ARGS_TARGET ?= prd
_BUILD_ARGS_TAG ?= latest

.DEFAULT_GOAL := help
.PHONY: help build build-dev build-all test test-dev test-all

help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

build: # Build [elasticms-admin] [prd] variant Docker images
	@$(MAKE) -s _build-prd

build-dev: # Build [elasticms-admin] [dev] variant Docker images
	@$(MAKE) -s _build-dev

build-all: # Build [elasticms-admin] [prd,dev] variant Docker images
	@$(MAKE) -s _build-prd
	@$(MAKE) -s _build-dev

_build-%: 
	@$(MAKE) -s _builder \
		-e _BUILD_ARGS_TAG="${ELASTICMS_ADMIN_VERSION}-$*" \
		-e _BUILD_ARGS_TARGET="$*"

_builder:
	@docker build \
		--build-arg VERSION_ARG="${ELASTICMS_ADMIN_VERSION}" \
		--build-arg RELEASE_ARG="${_BUILD_ARGS_TAG}" \
		--build-arg BUILD_DATE_ARG="${BUILD_DATE}" \
		--build-arg VCS_REF_ARG="${GIT_HASH}" \
		--target ${_BUILD_ARGS_TARGET} \
		--tag ${DOCKER_IMAGE_NAME}:${_BUILD_ARGS_TAG} .

test: # Test [elasticms-admin] [prd] variant Docker images
	@$(MAKE) -s _tester-prd

test-dev: # Test [elasticms-admin] [dev] variant Docker images
	@$(MAKE) -s _tester-dev

test-all: # Test [elasticms-admin] [prd,dev] variant Docker images
	@$(MAKE) -s _tester-prd
	@$(MAKE) -s _tester-dev

_tester-%: 
	@$(MAKE) -s _tester \
		-e DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${ELASTICMS_ADMIN_VERSION}-$*" \
		-e EMS_VERSION="${ELASTICMS_ADMIN_VERSION}"

_tester:
	@bats test/tests.bats