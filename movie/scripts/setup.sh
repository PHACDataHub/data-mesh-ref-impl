#!/bin/bash

./scripts/prepare_dot_env.sh create

./scripts/utils/docker/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
./scripts/utils/docker/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data
./scripts/utils/docker/create_volumes.sh schema-registry kafka-ce/schema-registry/data
./scripts/utils/docker/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins
./scripts/utils/docker/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/src kafka-ce/ksqldb-cli/test

./scripts/utils/docker/create_volumes.sh spooldir kafka-ce/connect/data/spooldir/error kafka-ce/connect/data/spooldir/processed kafka-ce/connect/data/spooldir/unprocessed
./scripts/utils/docker/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml

./scripts/utils/docker/create_volumes.sh neo4j neo4j/data neo4j/import neo4j/plugins
./scripts/utils/download/download_neo4j_plugins.sh neo4j

./scripts/utils/download/download_imdb_dataset.sh
