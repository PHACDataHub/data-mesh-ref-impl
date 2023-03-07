#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage ./scripts/kafka/create_subject.sh <subject> <schema_file>";
    exit 1
fi

subject=$1
schema_file=$2

source .env

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Creating subject ${subject} with schema ${schema_file} ..." 
escaped_avsc=$(cat $schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})
curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "$escaped_avsc" \
    http://${schema_registry_local_host}:${schema_registry_port}/subjects/${subject}/versions | jq .[]
echo ''
