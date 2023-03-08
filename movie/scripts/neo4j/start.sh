#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Start all services ...";
docker compose start neo4j
./scripts/utils/waits/wait_for_it.sh neo4j 60
echo "All services are started ✅";