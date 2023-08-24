#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./stop.sh <vm_name>"
    echo "   where vm_name is one of: ${valid_vms}"
    echo "Example: ./stop.sh kafka_cluster"
    exit
fi

if [ "$valid_vm" = "kafka_cluster" ] && [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

valid_vm=$1
vm_name=${valid_vm//_/-}

echo "Shutting down containers...";
docker compose -f docker-compose-${vm_name}.yml down
echo "Containers shutdown ✅";
