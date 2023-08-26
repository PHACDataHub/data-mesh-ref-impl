#!/bin/bash

source .env

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

# List the current Connect plugins
./scripts/list_plugins.sh

# List the current connector instances
./scripts/list_connectors.sh

curl -X POST http://${connect_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @conf/json/extracted_doc_entities_sink_connector.json
echo

curl -X POST http://${connect_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @conf/json/extracted_don_entities_sink_connector.json
echo

# List the current connector instances
./scripts/list_connectors.sh
