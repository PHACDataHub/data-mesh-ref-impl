#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./stop.sh
echo ''

echo "Shutting down containers...";
docker compose -f docker-compose.yml down
echo "Containers shutdown ✅";
echo ''

./scripts/delete_volumes.sh filepulse kafka-ce/connect/data/filepulse
./scripts/delete_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli
./scripts/delete_volumes.sh connect kafka-ce/connect
./scripts/delete_volumes.sh schema-registry kafka-ce/schema-registry
./scripts/delete_volumes.sh brokers kafka-ce/broker kafka-ce/broker2 kafka-ce/broker3
./scripts/delete_volumes.sh zookeeper kafka-ce/zk

rm -f .env

docker volume rm $(docker volume ls -qf dangling=true)