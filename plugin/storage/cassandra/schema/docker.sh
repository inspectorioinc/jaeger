#!/bin/bash
#
# This script is used in the Docker image jaegertracing/jaeger-cassandra-schema
# that allows installing Jaeger keyspace and schema without installing cqlsh.
set -e
CQLSH=${CQLSH:-"/usr/bin/cqlsh"}
CQLSH_HOST=${CQLSH_HOST:-"cassandra"}
CQLSH_PORT=${CQLSH_PORT:-"9042"}
CQLSH_SSL=${CQLSH_SSL:-""}
CASSANDRA_WAIT_TIMEOUT=${CASSANDRA_WAIT_TIMEOUT:-"60"}
DATACENTER=${DATACENTER:-"dc1"}
KEYSPACE=${KEYSPACE:-"jaeger_v1_${DATACENTER}"}
MODE=${MODE:-"test"}
USERNAME=${CASSANDRA_USERNAME:-"jaeger_insp"}
PASSWORD=${CASSANDRA_PASSWORD:-""}



total_wait=0
while true
do
  if [[ -z $SA_USERNAME ]] || [[ -z $SA_PASSWORD ]]  ; then
      ${CQLSH} ${CQLSH_SSL} -e "describe keyspaces"
  else
      ${CQLSH} --username=${SA_USERNAME} --password=${SA_PASSWORD} ${CQLSH_SSL} -e "describe keyspaces"
  fi
    
  if (( $? == 0 )); then
    break
  else
    if (( total_wait >= ${CASSANDRA_WAIT_TIMEOUT} )); then
      echo "Timed out waiting for Cassandra."
      exit 1
    fi
    echo "Cassandra is still not up at ${CQLSH_HOST}. Waiting 1 second."
    sleep 1s
    ((total_wait++))
  fi
done

if [[ -z $PASSWORD ]]; then    
    PASSWORD=$(cat /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    echo "Generating the PASSWORD ${PASSWORD}"
fi
echo "Generating the schema for the keyspace ${KEYSPACE} and datacenter ${DATACENTER}"

if [[ -z $SA_USERNAME ]] || [[ -z $SA_PASSWORD ]]  ; then
   #statements
MODE="${MODE}" DATACENTER="${DATACENTER}" KEYSPACE="${KEYSPACE}" USERNAME="$USERNAME" PASSWORD="$PASSWORD" /cassandra-schema/create.sh | ${CQLSH} ${CQLSH_SSL}
else
MODE="${MODE}" DATACENTER="${DATACENTER}" KEYSPACE="${KEYSPACE}" USERNAME="$USERNAME" PASSWORD="$PASSWORD" /cassandra-schema/create.sh | ${CQLSH} ${CQLSH_SSL} --username=${SA_USERNAME} --password=${SA_PASSWORD} ${CQLSH_SSL}
fi