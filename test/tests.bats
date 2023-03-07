#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_ROOT_DB_USER="${BATS_ROOT_DB_USER:-root}"
export BATS_ROOT_DB_PASSWORD="${BATS_ROOT_DB_PASSWORD:-password}"
export BATS_ROOT_DB_NAME="${BATS_ROOT_DB_NAME:-root}"

export BATS_DB_DRIVER="${BATS_DB_DRIVER:-pgsql}"
export BATS_DB_HOST="${BATS_DB_HOST:-postgresql}"
export BATS_DB_PORT="${BATS_DB_PORT:-5432}"
export BATS_DB_USER="${BATS_DB_USER:-example_adm}"
export BATS_DB_PASSWORD="${BATS_DB_PASSWORD:-abcd@.<efgh>.}"
export BATS_DB_NAME="${BATS_DB_NAME:-example}"

export BATS_REDIS_HOST="${BATS_REDIS_HOST:-redis}"
export BATS_REDIS_PORT="${BATS_REDIS_PORT:-6379}"

export BATS_JOBS_ENABLED="${BATS_JOBS_ENABLED:-true}"
export BATS_METRICS_ENABLED="${BATS_METRICS_ENABLED:-true}"

export BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME="ems-config/demo/config/elasticms"
export BATS_S3_SKELETON_CONFIG_BUCKET_NAME="ems-config/demo/config/skeleton"
export BATS_S3_STORAGE_BUCKET_NAME="demo-ems-storage"
export BATS_S3_ENDPOINT_URL="http://localhost:19000"
export BATS_S3_ACCESS_KEY_ID="mock"
export BATS_S3_SECRET_ACCESS_KEY="SecretAccessKey"
export BATS_S3_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="${BATS_S3_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${BATS_S3_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${BATS_S3_DEFAULT_REGION}"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_ELASTICMS_ADMIN_USERNAME="demo-bats"
export BATS_ELASTICMS_ADMIN_PASSWORD="bats"
export BATS_ELASTICMS_ADMIN_EMAIL="demo.admin.s3.bats@example.com"
export BATS_ELASTICMS_ADMIN_ENVIRONMENT="demo-dev"

export BATS_ELASTICMS_SKELETON_ADMIN_URL="http://demo-admin.localhost"
export BATS_ELASTICMS_SKELETON_BACKEND_URL="http://demo-admin-dev.localhost:9000"
export BATS_ELASTICMS_SKELETON_ENVIRONMENT="demo-preview-dev"

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_EMS_VERSION="${EMS_VERSION:-5.x}"
export BATS_DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-docker.io/elasticms/admin:rc}"

@test "[$TEST_FILE] Prepare Skeleton [$BATS_EMS_VERSION]." {

  run git clone -b ${BATS_EMS_VERSION} git@github.com:ems-project/elasticms-demo.git ${BATS_TEST_DIRNAME%/}/demo
  run mkdir -p ${BATS_TEST_DIRNAME%/}/demo/dist
  run npm install --save-dev webpack --prefix ${BATS_TEST_DIRNAME%/}/demo ${BATS_TEST_DIRNAME%/}/demo
  run npm run --prefix ${BATS_TEST_DIRNAME%/}/demo prod
  run chmod 777 ${BATS_TEST_DIRNAME%/}/demo/skeleton

}

@test "[$TEST_FILE] Starting Services (PostgreSQL, Elasticsearch, Redis, Minio, Tika)." {

  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d postgresql es01 es02 es03 redis tika minio
  docker_wait_for_log postgresql 240 ".*database system is ready to accept connections"
  docker_wait_for_log es01 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  docker_wait_for_log es02 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  docker_wait_for_log es03 120 ".*\"type\": \"server\", \"timestamp\": \".*\", \"level\": \".*\", \"component\": \".*\", \"cluster.name\": \".*\", \"node.name\": \".*\", \"message\": \"started\".*"
  docker_wait_for_log redis 240 "Ready to accept connections"
  docker_wait_for_healthy minio 120
  docker_wait_for_healthy tika 120

}

@test "[$TEST_FILE] Create Configuration S3 Bucket." {

  run aws s3 mb s3://${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%%/*} --endpoint-url ${BATS_S3_ENDPOINT_URL}
  assert_output -l -r "make_bucket: ${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%%/*}"

}

@test "[$TEST_FILE] Create Storage S3 Bucket." {

  run aws s3 mb s3://${BATS_S3_STORAGE_BUCKET_NAME%%/*} --endpoint-url ${BATS_S3_ENDPOINT_URL}
  assert_output -l -r "make_bucket: ${BATS_S3_STORAGE_BUCKET_NAME%%/*}"

}

@test "[$TEST_FILE] Configure Database." {

  run configure_database ${BATS_STORAGE_SERVICE_NAME} ${BATS_DB_DRIVER} ${BATS_ROOT_DB_USER} ${BATS_ROOT_DB_PASSWORD} ${BATS_ROOT_DB_NAME} ${BATS_DB_PORT} ${BATS_DB_HOST} ${BATS_DB_USER} ${BATS_DB_PASSWORD} ${BATS_DB_NAME}
  assert_output -l -r "${BATS_DB_DRIVER} OK"

}

@test "[$TEST_FILE] Loading Elasticms Config files in Configuration S3 Bucket." {

  run aws s3api put-bucket-acl --bucket s3://${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%/} --acl public-read --endpoint-url ${BATS_S3_ENDPOINT_URL}

  # TODO : update demo project to use more env vars in config file and use theses here (instead of manage own config files)
  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run copy_to_s3bucket $file ${BATS_S3_ELASTICMS_CONFIG_BUCKET_NAME%/}/ ${BATS_S3_ENDPOINT_URL}
    assert_output -l -r 'S3 COPY OK'

  done
}

@test "[$TEST_FILE] Loading Skeleton Config files in Configuration S3 Bucket." {

  run aws s3api put-bucket-acl --bucket s3://${BATS_S3_SKELETON_CONFIG_BUCKET_NAME%/} --acl public-read --endpoint-url ${BATS_S3_ENDPOINT_URL}

  # TODO : update demo project to use more env vars in config file and use theses here (instead of manage own config files)
  for file in ${BATS_TEST_DIRNAME%/}/configs/skeleton/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run copy_to_s3bucket $file ${BATS_S3_SKELETON_CONFIG_BUCKET_NAME%/}/ ${BATS_S3_ENDPOINT_URL}
    assert_output -l -r 'S3 COPY OK'

  done
}

@test "[$TEST_FILE] Starting Elasticms." {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip es01):9200
  export BATS_S3_ENDPOINT_URL=http://$(docker_ip minio):9000
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(docker_ip tika):9998
  export BATS_REDIS_HOST=$(docker_ip redis)

  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d elasticms

}

@test "[$TEST_FILE] Check Elasticms startup messages in container logs." {
  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    docker_wait_for_log ems 15 "Install \[ ${_name} \] CMS Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    docker_wait_for_log ems 15 "Doctrine database migration for \[ ${_name} \] CMS Domain run successfully ..."
    docker_wait_for_log ems 15 "Elasticms assets installation for \[ ${_name} \] CMS Domain run successfully ..."
    docker_wait_for_log ems 15 "Elasticms warming up for \[ ${_name} \] CMS Domain run successfully ..."
  done

  docker_wait_for_log ems 15 "NOTICE: ready to handle connections"
  docker_wait_for_log ems 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"

}

@test "[$TEST_FILE] Starting Skeleton." {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip es01):9200
  export BATS_S3_ENDPOINT_URL=http://$(docker_ip minio):9000
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(docker_ip tika):9998
  export BATS_REDIS_HOST=$(docker_ip redis)

  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml up -d emsch

}

@test "[$TEST_FILE] Check Skeleton startup messages in containers logs." {
  for file in ${BATS_TEST_DIRNAME%/}/configs/skeleton/*.env ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    docker_wait_for_log emsch 15 "Install \[ ${_name} \] Skeleton Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    docker_wait_for_log emsch 15 "Elasticms assets installation for \[ ${_name} \] Skeleton Domain run successfully ..."
    docker_wait_for_log emsch 15 "Elasticms warming up for \[ ${_name} \] Skeleton Domain run successfully ..."
  done

  docker_wait_for_log emsch 15 "NOTICE: ready to handle connections"
  docker_wait_for_log emsch 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}

@test "[$TEST_FILE] Create Elasticms Super Admin user." {

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:create --super-admin --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ${BATS_ELASTICMS_ADMIN_EMAIL} ${BATS_ELASTICMS_ADMIN_PASSWORD}"
  assert_output -r ".*\[OK\] Created user \"${BATS_ELASTICMS_ADMIN_USERNAME}\""

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_API"
  assert_output -r ".*\[OK\] Role \"ROLE_API\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_COPY_PASTE"
  assert_output -r ".*\[OK\] Role \"ROLE_COPY_PASTE\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_ALLOW_ALIGN"
  assert_output -r ".*\[OK\] Role \"ROLE_ALLOW_ALIGN\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_FORM_CRM"
  assert_output -r ".*\[OK\] Role \"ROLE_FORM_CRM\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

  run docker exec ems sh -c "/opt/bin/${BATS_ELASTICMS_ADMIN_ENVIRONMENT} emsco:user:promote --no-debug ${BATS_ELASTICMS_ADMIN_USERNAME} ROLE_TASK_MANAGER"
  assert_output -r ".*\[OK\] Role \"ROLE_TASK_MANAGER\" has been added to user \"${BATS_ELASTICMS_ADMIN_USERNAME}\".*"

}

@test "[$TEST_FILE] Login to Elasticms for configuration." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:login --username=${BATS_ELASTICMS_ADMIN_USERNAME} --password=${BATS_ELASTICMS_ADMIN_PASSWORD} ${BATS_ELASTICMS_SKELETON_BACKEND_URL}
  assert_output -r ".*\[OK\] Welcome ${BATS_ELASTICMS_ADMIN_USERNAME} on ${BATS_ELASTICMS_BACKEND_URL}"

}

@test "[$TEST_FILE] Upload Elasticms assets." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} emsch:local:folder-upload -- /opt/src/admin/assets
  assert_output -r ".*\[OK\] .* \(on .*\) assets have been uploaded"

}

@test "[$TEST_FILE] Configure Elasticms Filters." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter dutch_stemmer
  assert_output -r "filter dutch_stemmer with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter dutch_stop
  assert_output -r "filter dutch_stop with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter empty_elision
  assert_output -r "filter empty_elision with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter english_stemmer
  assert_output -r "filter english_stemmer with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter english_stop
  assert_output -r "filter english_stop with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter french_elision
  assert_output -r "filter french_elision with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter french_stemmer
  assert_output -r "filter french_stemmer with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter french_stop
  assert_output -r "filter french_stop with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter german_stemmer
  assert_output -r "filter german_stemmer with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update filter german_stop
  assert_output -r "filter german_stop with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Analyzers." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer alpha_order
  assert_output -r "analyzer alpha_order with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer dutch_for_highlighting
  assert_output -r "analyzer dutch_for_highlighting with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer english_for_highlighting
  assert_output -r "analyzer english_for_highlighting with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer french_for_highlighting
  assert_output -r "analyzer french_for_highlighting with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer german_for_highlighting
  assert_output -r "analyzer german_for_highlighting with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update analyzer html_strip
  assert_output -r "analyzer html_strip with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Schedules." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update schedule check-aliases
  assert_output -r "schedule check-aliases with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update schedule clear-logs
  assert_output -r "schedule clear-logs with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update schedule publish-releases
  assert_output -r "schedule publish-releases with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update schedule remove-expired-submissions
  assert_output -r "schedule remove-expired-submissions with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Wysiwygs." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-style-set bootstrap
  assert_output -r "wysiwyg-style-set bootstrap with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-style-set revealjs
  assert_output -r "wysiwyg-style-set revealjs with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-profile Full
  assert_output -r "wysiwyg-profile Full with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-profile Light
  assert_output -r "wysiwyg-profile Light with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-profile Sample
  assert_output -r "wysiwyg-profile Sample with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update wysiwyg-profile Standard
  assert_output -r "wysiwyg-profile Standard with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms I18N." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n config
  assert_output -r "i18n config with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n ems.documentation.body
  assert_output -r "i18n ems.documentation.body with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n locale.fr
  assert_output -r "i18n locale.fr with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n locale.nl
  assert_output -r "i18n locale.nl with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n locale.de
  assert_output -r "i18n locale.de with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n locale.en
  assert_output -r "i18n locale.en with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n locales
  assert_output -r "i18n locales with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update i18n asset.type.manual
  assert_output -r "i18n asset.type.manual with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Environments." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update environment preview
  assert_output -r "environment preview with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update environment live
  assert_output -r "environment live with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Forms." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form add_menu_item
  assert_output -r "form add_menu_item with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form dashboard_default_search_options
  assert_output -r "form dashboard_default_search_options with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form dashboard_sitemap_options
  assert_output -r "form dashboard_sitemap_options with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form label
  assert_output -r "form label with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form menu-locales
  assert_output -r "form menu-locales with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update form search_fields
  assert_output -r "form search_fields with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms ContentTypes." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type category
  assert_output -r "content-type category with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type form_instance
  assert_output -r "content-type form_instance with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type label
  assert_output -r "content-type label with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type page
  assert_output -r "content-type page with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type route
  assert_output -r "content-type route with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type section
  assert_output -r "content-type section with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type slideshow
  assert_output -r "content-type slideshow with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type template
  assert_output -r "content-type template with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update content-type template_ems
  assert_output -r "content-type template_ems with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms QuerySearches." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update query-search categories
  assert_output -r "query-search categories with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update query-search pages
  assert_output -r "query-search pages with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update query-search documents
  assert_output -r "query-search documents with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update query-search forms
  assert_output -r "query-search forms with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Dashboards." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update dashboard default-search
  assert_output -r "dashboard default-search with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update dashboard sitemap
  assert_output -r "dashboard sitemap with id .* has been updated"

}

@test "[$TEST_FILE] Configure Elasticms Channels." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update channel preview
  assert_output -r "channel preview with id .* has been updated"

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:admin:update channel live
  assert_output -r "channel live with id .* has been updated"

}

@test "[$TEST_FILE] Rebuild Elasticms Environments." {

  envs=(`docker exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:list --no-debug`)

  for e in ${envs[@]}; do
    run docker exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:rebuild ${e} --no-debug --yellow-ok
    assert_output -r "The alias .* is now point to .*"
  done

}

@test "[$TEST_FILE] Activate Elasticms content types." {

  run docker exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:contenttype:activate --all

  # Missing message when action is done (with success or not)
  # assert_output -r ""

}

@test "[$TEST_FILE] Push templates, routes and translations." {

  run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:local:push --force

  # Missing message when action is done (with success or not)
  # assert_output -r ""

}

@test "[$TEST_FILE] Upload documents." {

  for type in page structure slideshow form_instance asset; do
    run docker exec emsch ${BATS_ELASTICMS_SKELETON_ENVIRONMENT} ems:document:upload ${type}
    # Missing message when action is done (with success or not)
    # assert_output -r ""
  done

}

@test "[$TEST_FILE] Align live." {

  run docker exec ems ${BATS_ELASTICMS_ADMIN_ENVIRONMENT} ems:environment:align preview live --force --no-debug
  assert_output -r ".*\[OK\] Environments preview -> live were aligned.*"

}

@test "[$TEST_FILE] Check for Elasticms Default Index page response code 200" {

  retry 12 5 curl_container ems :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Elasticms status page response code 200 for all configured domains" {

  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do

    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    retry 12 5 curl_container ems :9000/status -H "Host: ${SERVER_NAME}" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    retry 12 5 curl_container ems :9000/health_check.json -H "Host: ${SERVER_NAME}" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    rm /tmp/$_name

  done

}

@test "[$TEST_FILE] Check for Elasticms metrics page response code 200 for all configured domains" {

  for file in ${BATS_TEST_DIRNAME%/}/configs/elasticms/*.env ; do

    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    retry 12 5 curl_container ems :9090/metrics -H "Host: ${SERVER_NAME}:9090" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    rm /tmp/$_name

  done

}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {

  retry 12 5 curl_container ems :9000/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {

  retry 12 5 curl_container ems :9000/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {

  retry 12 5 curl_container ems :9000/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'

}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml stop
  command docker-compose -f ${BATS_TEST_DIRNAME%/}/docker-compose.yml rm -v -f
}
