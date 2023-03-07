#!/bin/bash

source .env

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "List all current subjects ..." 
echo "curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]"
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''
