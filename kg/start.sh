#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./start.sh <vm_name>"
    echo "   where vm_name is one of: ${valid_vms}"
    echo "Example: ./start.sh kafka_cluster"
    exit
fi

if [ "$valid_vm" = "kafka_cluster" ] && [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

valid_vm=$1
vm_name=${valid_vm//_/-}

echo "Start all services ...";
docker compose -f docker-compose-${vm_name}.yml up -d

if [ "$valid_vm" = "kafka_cluster" ]; then
    ./scripts/wait_for_kafka.sh
fi

if [ "$valid_vm" = "neo4j_cluster" ]; then
    ./scripts/wait_for_it.sh neo4j 60
fi

echo "All services have started ✅";
