#!/bin/bash

./scripts/setup_neo4j_database.sh
./scripts/create_spooldir_connectors.sh
./scripts/create_neo4j_connectors.sh
./scripts/post_process_neo4j.sh