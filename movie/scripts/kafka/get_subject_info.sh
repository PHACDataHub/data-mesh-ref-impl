#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/get_subject_info.sh <subject>";
    exit 1
fi

subject=$1

source .env

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Find ID of the ${subject}..." 
schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions/latest | jq .id)
echo schema_id=${schema_id}
echo ''
echo ''

echo "Find details of the ${subject}..." 
echo "curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions/latest"
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions/latest
echo ''
echo ''

echo "List all versions of ${subject}..." 
echo "curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions | jq"
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions | jq
echo ''
