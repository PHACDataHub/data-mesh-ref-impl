#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Stopping all services ...";
docker compose -f docker-compose-neo4j.yml stop
echo "All services are stopped ✅";
