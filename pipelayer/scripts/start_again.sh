#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Start all services ...";
docker compose -f docker-compose-pipelayer.yml start
./scripts/pipelayer/wait_for_it.sh pipelayer 60
echo "All services are started ✅";