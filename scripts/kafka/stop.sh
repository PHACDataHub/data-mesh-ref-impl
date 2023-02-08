#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

if [ ! -d "vol/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Stopping all services ...";
docker compose -f docker-compose-kafka-ce.yml stop
echo "All services are stopped ✅";
