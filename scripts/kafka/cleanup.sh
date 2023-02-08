#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

if [ ! -d "vol/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./scripts/kafka/stop.sh
echo ''

echo "Shutting down containers...";
docker compose -f docker-compose-kafka-ce.yml down
echo "Containers shutdown ✅";
echo ''

echo "Removing instance files ...";
sudo rm -rf vol*
sudo rm -rf kafka/plugins
echo "Instance files removed ✅";
