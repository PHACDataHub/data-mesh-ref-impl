#!/bin/bash

source .env

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

curl -X POST http://${connect_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @conf/neo4j/sink_connector.json
echo

./scripts/utils/waits/wait_for_import.sh 6505739