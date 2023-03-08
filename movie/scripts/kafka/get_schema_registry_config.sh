#!/bin/bash

source .env

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Top level schema compatibility configuration ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/config | jq .[]
echo ''
