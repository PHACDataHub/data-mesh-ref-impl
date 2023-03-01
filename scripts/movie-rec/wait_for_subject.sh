#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/wait_for_subject.sh <subject>";
    exit 1
fi

subject=$1

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=8081

error_code=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions/latest | jq .error_code)
echo "Wait for the subject ${subject} be ready ...";
while [ "$error_code" = "40401" ]
do
    error_code=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions/latest | jq .error_code)
    sleep 1
done
echo ''

echo "List all versions of ${subject}..." 
echo "curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions | jq"
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions | jq
echo ''
