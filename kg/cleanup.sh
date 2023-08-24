#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./cleanup.sh <vm_name>"
    echo "   where vm_name is one of: ${valid_vms}"
    echo "Example: ./cleanup.sh kafka_cluster"
    exit
fi

valid_vm=$1
vm_name=${valid_vm//_/-}

if [ "$valid_vm" = "kafka_cluster" ] && [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Shutting down containers...";
docker compose -f docker-compose-${vm_name}.yml down
echo "Containers shutdown ✅";

if [ "$valid_vm" = "kafka_cluster" ]; then
    ./scripts/delete_volumes.sh filepulse kafka-ce/connect/data/filepulse
    ./scripts/delete_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli
    ./scripts/delete_volumes.sh connect kafka-ce/connect/data
    ./scripts/delete_volumes.sh schema-registry kafka-ce/schema-registry
    ./scripts/delete_volumes.sh brokers kafka-ce/broker kafka-ce/broker2 kafka-ce/broker3 kafka-ce/broker4
    ./scripts/delete_volumes.sh zookeeper kafka-ce/zk
    ./scripts/delete_volumes.sh postgres/postgres/data
fi

if [ "$valid_vm" = "neo4j_cluster" ]; then
    ./scripts/delete_volumes.sh neo4j neo4j/data neo4j/import neo4j/logs
fi

rm -f .env

docker volume rm $(docker volume ls -qf dangling=true)