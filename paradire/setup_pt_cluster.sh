#!/bin/bash

valid_pts="AB BC MB NB NL NT NS NU ON PE QC SK YT"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_pts} | grep $1)" ]; then
    echo "Usage: ./setup_pt_cluster.sh <pt> <f_cluster_ip>"
    echo "   where valid_pt is one of: ${valid_pts}"
    echo "Example: ./setup_pt_cluster.sh BC 35.203.83.135"
    exit
fi

PT=$1

if [ -z "$2" ]; then
    echo WARNING: default IP of 35.203.83.135 is used for F cluster.
    F_KAFKA_CLUSTER_IP=35.203.83.135
else
    F_KAFKA_CLUSTER_IP=$2
fi

if [ -d "kafka-ce/zk" ]; then
    echo "The cluster is already setup ❌";
    exit 1
fi

./scripts/prepare_dot_env.sh $PT $F_KAFKA_CLUSTER_IP

./scripts/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
./scripts/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data kafka-ce/broker4/data
./scripts/create_volumes.sh schema-registry kafka-ce/schema-registry/data
./scripts/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins
./scripts/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/scripts
./scripts/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml

./scripts/create_volumes.sh nlp-tasks nlp-tasks/keyphrase-extractor/cache

./scripts/create_volumes.sh neo4j neo4j/data neo4j/import neo4j/logs neo4j/plugins
./scripts/download_neo4j_plugins.sh neo4j
