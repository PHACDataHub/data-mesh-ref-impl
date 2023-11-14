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
  -d @analytics/pt_connectors/event_sink_connector_1.json
echo

# List the current connector instances
./scripts/list_connectors.sh

echo Wait for sinking key entities
sleep 10

curl -X POST http://${connect_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @analytics/pt_connectors/event_sink_connector_2.json
echo

# List the current connector instances
./scripts/list_connectors.sh
