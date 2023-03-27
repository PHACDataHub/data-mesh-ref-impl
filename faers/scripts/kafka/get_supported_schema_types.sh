#!/bin/bash

source .env

schema_registry_container=schema-registry
schema_registry_host=${SCHEMA_REGISTRY_HOST}
schema_registry_port=${SCHEMA_REGISTRY_PORT}

curl --silent http://${schema_registry_host}:${schema_registry_port}/schemas/types