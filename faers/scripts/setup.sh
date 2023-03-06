#!/bin/bash

./scripts/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
./scripts/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data
./scripts/create_volumes.sh schema-registry kafka-ce/schema-registry/data
./scripts/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins kafka-ce/connect2/data kafka-ce/connect2/plugins kafka-ce/connect3/data kafka-ce/connect3/plugins
./scripts/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/src kafka-ce/ksqldb-cli/test

./scripts/create_volumes.sh spooldir kafka-ce/connect/data/spooldir/error kafka-ce/connect/data/spooldir/processed kafka-ce/connect/data/spooldir/unprocessed
./scripts/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml

./scripts/create_volumes.sh neo4j neo4j/data neo4j/import neo4j/plugins
./scripts/download_neo4j_plugins.sh neo4j