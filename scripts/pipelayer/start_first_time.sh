#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

NETWORK_NAME=backend

echo "Creating network if it does not exist..."
docker network inspect ${NETWORK_NAME} >/dev/null 2>&1 || \
    docker network create --driver bridge ${NETWORK_NAME}

echo "Start all services ...";
docker compose -f docker-compose-pipelayer.yml up --build -d
./scripts/pipelayer/wait_for_it.sh pipelayer 60
echo "All services are started ✅";