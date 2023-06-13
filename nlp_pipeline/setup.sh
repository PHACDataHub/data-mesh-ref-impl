#!/bin/bash

./scripts/prepare_dot_env.sh create

./scripts/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
./scripts/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data
./scripts/create_volumes.sh schema-registry kafka-ce/schema-registry/data
./scripts/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins
./scripts/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/scripts

./scripts/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml
