#!/bin/bash

./scripts/neo4j/stop.sh
echo ''

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Shutting down containers...";
docker compose -f docker-compose-neo4j.yml down
echo "Containers shutdown ✅";

sudo rm -rf data/neo4j
sudo rm -rf data/neo4j_plugins