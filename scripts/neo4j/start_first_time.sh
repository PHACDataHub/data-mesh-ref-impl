#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Start all services ...";
docker compose -f docker-compose-neo4j.yml up -d
./scripts/neo4j/wait_for_it.sh neo4j 60
echo "All services are started ✅";