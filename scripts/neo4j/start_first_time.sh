#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

mkdir -p data/neo4j_plugins

wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/5.5.0/apoc-5.5.0-extended.jar 
mv apoc-5.5.0-extended.jar data/neo4j_plugins/.

echo "Start all services ...";
docker compose -f docker-compose-neo4j.yml up -d
./scripts/neo4j/wait_for_it.sh neo4j 60
echo "All services are started ✅";