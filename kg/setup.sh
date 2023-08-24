#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./setup.sh <vm_name> <kafka_cluster_ip>"
    echo "   where:" 
    echo "      - vm_name is one of: ${valid_vms}" 
    echo "      - kafka_cluster_ip is a valid IP such as 10.162.0.15. It is for all other VMs except kafka_cluster" 
    echo "Example:"
    echo "    ./setup.sh kafka_cluster"
    echo "    ./setup.sh dedup_by_id 10.162.0.15"
    exit
fi

valid_vm=$1

if [ "$valid_vm" != "kafka_cluster" ] && [ -z "$2" ]; then
    echo "Please specify <kafka_cluster_ip>";
    exit 1
fi

./scripts/prepare_dot_env.sh $2

if [ "$valid_vm" = "kafka_cluster" ]; then
    if [ -d "kafka-ce/zk" ]; then
        echo "The cluster is already setup ❌";
        exit 1
    fi
    ./scripts/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
    ./scripts/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data kafka-ce/broker4/data
    ./scripts/create_volumes.sh schema-registry kafka-ce/schema-registry/data
    ./scripts/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins
    ./scripts/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/scripts
    ./scripts/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml
    ./scripts/create_volumes.sh postgres postgres/postgres/data
fi

if [ "$valid_vm" = "neo4j_cluster" ]; then
    ./scripts/create_volumes.sh neo4j neo4j/data neo4j/import neo4j/logs neo4j/plugins
    ./scripts/download_neo4j_plugins.sh neo4j
fi
