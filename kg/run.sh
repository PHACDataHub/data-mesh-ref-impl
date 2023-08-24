#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./run.sh <vm_name>"
    echo "   where vm_name is one of: ${valid_vms}"
    echo "Example: ./run.sh kafka_cluster"
    exit
fi

valid_vm=$1

if [ "$valid_vm" = "kafka_cluster" ] && [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

if [ "$valid_vm" = "kafka_cluster" ]; then
    ./create_postgres_connectors.sh kafka_cluster
    ./produce_factiva_articles.sh
fi

if [ "$valid_vm" = "neo4j_cluster" ]; then
    ./create_neo4j_database.sh
    ./create_neo4j_connectors.sh
fi
