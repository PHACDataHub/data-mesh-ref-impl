#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/delete_subject.sh <subject>";
    exit 1
fi

subject=$1

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=8081

echo "Delete ${subject} subject ..." 
echo "curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject} | jq .[]"
curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject} | jq .[]
echo ''

./scripts/movie-rec/list_subjects.sh