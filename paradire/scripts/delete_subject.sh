#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/delete_subject.sh <subject>";
    exit 1
fi

subject=$1

source .env

schema_registry_container=schema-registry
schema_registry_host=${SCHEMA_REGISTRY_HOST}
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Delete subject ${subject} ..." 
echo "curl --silent -X DELETE http://${schema_registry_host}:${schema_registry_port}/subjects/${subject} | jq .[]"
curl --silent -X DELETE http://${schema_registry_host}:${schema_registry_port}/subjects/${subject} | jq .[]
echo ''
