#!/bin/bash

set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Start all services ...";
docker compose -f docker-compose.yml up -d
./scripts/utils/waits/wait_for_kafka.sh
./scripts/utils/waits/wait_for_it.sh neo4j 60
echo "All services have started ✅";

./scripts/run.sh