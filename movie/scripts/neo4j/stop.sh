#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Stopping all services ...";
docker compose stop neo4j
echo "All services are stopped ✅";
