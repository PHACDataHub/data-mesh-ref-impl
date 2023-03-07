#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./scripts/stop.sh
echo ''

set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Shutting down containers...";
docker compose -f docker-compose.yml down
echo "Containers shutdown ✅";
echo ''

./scripts/utils/docker/delete_volumes.sh neo4j neo4j/data neo4j/import neo4j/plugins

./scripts/utils/docker/delete_volumes.sh filepulse kafka-ce/connect/data/filepulse
./scripts/utils/docker/delete_volumes.sh spooldir kafka-ce/connect/data/spooldir

./scripts/utils/docker/delete_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli
./scripts/utils/docker/delete_volumes.sh connect kafka-ce/connect kafka-ce/connect2 kafka-ce/connect3
./scripts/utils/docker/delete_volumes.sh schema-registry kafka-ce/schema-registry
./scripts/utils/docker/delete_volumes.sh brokers kafka-ce/broker kafka-ce/broker2 kafka-ce/broker3
./scripts/utils/docker/delete_volumes.sh zookeeper kafka-ce/zk
