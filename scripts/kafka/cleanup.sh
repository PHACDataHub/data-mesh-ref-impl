#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

if [ ! -d "vol/zk" ]; then
    echo "The cluster is not setup yet.";
    exit 1
fi

./scripts/kafka/stop.sh
echo ''

echo "Shutting down containers...";
if [[ $OSTYPE == 'Linux' ]]; then
    docker compose -f docker-compose-kafka.yml down
fi
if [[ $OSTYPE == 'Darwin' ]]; then
    docker compose -f docker-compose-kafka-osx.yml down
fi
echo "Containers shutdown ✅";
echo ''

echo "Removing instance files ...";
sudo rm -rf vol*
sudo rm -rf data/error data/unprocessed data/processed
echo "Instance files removed ✅";
