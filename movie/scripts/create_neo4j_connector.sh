#!/bin/bash

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

# List the current Connect plugins
./scripts/kafka/list_plugins.sh

# List the current connector instances
./scripts/kafka/list_connectors.sh

curl -X POST http://${connect_local_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @conf/json/neo4j_sink_connector.json

# List the current connector instances
./scripts/kafka/list_connectors.sh
