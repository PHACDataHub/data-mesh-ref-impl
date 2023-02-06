#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

if [ ! -d "vol/zk" ]; then
    echo "The cluster is not setup yet.";
    exit 1
fi

echo "Start all services ...";
docker compose -f docker-compose-kafka.yml up -d
echo "All services are started ✅";

./scripts/kafka/wait_for_services.sh

