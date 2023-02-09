#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Restart all services ...";
docker compose -f docker-compose-kafka-ce.yml start
echo "All services are restarted ✅";

./scripts/kafka/wait_for_services.sh