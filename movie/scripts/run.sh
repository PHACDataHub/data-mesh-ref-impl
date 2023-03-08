#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./scripts/import_imdb_dataset.sh 
./scripts/create_rss_filepulse_connector.sh
./scripts/create_neo4j_connector.sh