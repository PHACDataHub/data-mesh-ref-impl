#!/bin/bash

connect=localhost:8083

# List the current Connect plugins
./scripts/movie-rec/list_connect_plugins.sh

# List the current connector instances
./scripts/movie-rec/list_connectors.sh

curl -X POST http://${connect}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @conf/movie-rec/neo4j/neo4j_screenrant_sink_connector.json

# List the current connector instances
./scripts/movie-rec/list_connectors.sh

# ./scripts/neo4j/wait_for_import.sh