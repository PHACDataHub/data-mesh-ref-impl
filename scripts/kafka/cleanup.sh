#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

if [ ! -d "kafka-ce/zk" ]; then
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
for item in kafka-ce/zk kafka-ce/broker kafka-ce/broker2 kafka-ce/broker3 kafka-ce/schema-registry kafka-ce/connect kafka-ce/plugins kafka-ce/ksqldb-cli
do
    sudo rm -rf $item;
done
echo "Instance files removed ✅";
