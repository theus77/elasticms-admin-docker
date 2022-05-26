function configure_database {
  local -r _container_name=${1}

  local -r _DB_DRIVER=${2}
  local -r _DB_ROOT_USER=${3}
  local -r _DB_ROOT_PASSWORD=${4}
  local -r _DB_ROOT_NAME=${5}

  local -r _DB_PORT=${6}
  local -r _DB_HOST=${7}
  local -r _DB_USER=${8}
  local -r _DB_PASSWORD=${9}
  local -r _DB_NAME=${10}

  if [ ${_DB_DRIVER} = mysql ] ; then
    run configure_mysql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME}
  elif [ ${_DB_DRIVER} = pgsql ] ; then
    run configure_pgsql ${_container_name} ${_DB_ROOT_USER} ${_DB_ROOT_PASSWORD} ${_DB_ROOT_NAME} ${_DB_PORT} ${_DB_HOST} ${_DB_USER} ${_DB_PASSWORD} ${_DB_NAME}
  else
    echo "Driver ${_DB_DRIVER} not supported"
    return -1
  fi;

  if [ $? -eq 0 ]; then
    echo "${_DB_DRIVER} OK"
    return 0
  else
    echo "${_DB_DRIVER} KO"
    false
  fi

}

function configure_mysql {
  local -r _container_name=$1
  local -r _filename=$2

  local -r _DB_ROOT_USER=${3}
  local -r _DB_ROOT_PASSWORD=${4}
  local -r _DB_ROOT_NAME=${5}

  local -r _DB_PORT=${6}
  local -r _DB_HOST=${7}
  local -r _DB_USER=${8}
  local -r _DB_PASSWORD=${9}
  local -r _DB_NAME=${10}

  local -r _basename=$(basename $_filename)
  local -r _relative=${_filename#"${BATS_TEST_DIRNAME}/"}

  local -r _name=${_basename%.*}

  local _mysql_status=0

  run docker exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE DATABASE ${_DB_NAME};\""
  run docker exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"CREATE USER '${_DB_USER}'@'%' IDENTIFIED BY '${_DB_PASSWORD}';\""
  run docker exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"GRANT ALL PRIVILEGES ON ${_DB_NAME} . * TO '${_DB_USER}'@'%';\""
  run docker exec ${_container_name} sh -c "mysql -u${_DB_ROOT_USER} -p${_DB_ROOT_PASSWORD} -vvv -e \"FLUSH PRIVILEGES;\""
  assert_output -l -r "Query OK, .* rows affected \(.*\)"

  if [ ! "$?" -eq 0 ]; then
    _mysql_status=1
  fi

  if [ "$_mysql_status" -eq 0 ]; then
    echo "${_DB_DRIVER} OK"
    return 0
  else
    echo "${_DB_DRIVER} KO"
    false
  fi

}

function configure_pgsql {
  local -r _container_name=${1}

  local -r _DB_ROOT_USER=${2}
  local -r _DB_ROOT_PASSWORD=${3}
  local -r _DB_ROOT_NAME=${4}

  local -r _DB_PORT=${5}
  local -r _DB_HOST=${6}
  local -r _DB_USER=${7}
  local -r _DB_PASSWORD=${8}
  local -r _DB_NAME=${9}

  local _pgsql_status=0

  run docker exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE USER ${_DB_USER} WITH PASSWORD '${_DB_PASSWORD}';\""

  if [ ! "$?" -eq 0 ]; then
    _pgsql_status=1
  fi

  run docker exec ${_container_name} sh -c "PGHOST=${_DB_HOST} PGPORT=${_DB_PORT} PGDATABASE=${_DB_ROOT_NAME} PGUSER=${_DB_ROOT_USER} PGPASSWORD=${_DB_ROOT_PASSWORD} psql --command=\"CREATE DATABASE ${_DB_NAME} WITH OWNER ${_DB_USER};\""

  if [ ! "$?" -eq 0 ]; then
    _pgsql_status=1
  fi

  if [ "$_pgsql_status" -eq 0 ]; then
    return 0
  else
    return -1
  fi

}

function copy_to_s3bucket {

  local -r _filename=$1
  local -r _bucket=$2
  local -r _endpoint=$3

  local -r _basename=$(basename $_filename)
  local -r _name=${_basename%.*}
  local -r _relative=${_filename#"${BATS_TEST_DIRNAME}/"}

  local -r _copy_status=0

  run aws s3 cp ${_filename} s3://${_bucket%/}/ --endpoint-url ${_endpoint}
  assert_output -l -r ".*upload: test/${_relative} to s3://${_bucket%/}/${_basename}.*"

  if [ ! "$?" -eq 0 ]; then
    _copy_status=1
  fi

  if [ "$_copy_status" -eq 0 ]; then
    echo "S3 COPY OK"
    return 0
  else
    echo "S3 COPY KO"
    false
  fi

}