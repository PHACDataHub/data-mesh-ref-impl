#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./create_neo4j_database.sh
./produce_messages.sh
./create_neo4j_connectors.sh