#!/bin/bash

./utils/prepare_dot_env.sh create

./utils/create_volumes.sh zookeeper kafka-ce/zk/data kafka-ce/zk/txn-logs
./utils/create_volumes.sh brokers kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data
./utils/create_volumes.sh schema-registry kafka-ce/schema-registry/data
./utils/create_volumes.sh connect kafka-ce/connect/data kafka-ce/connect/plugins
./utils/create_volumes.sh ksqldb-cli kafka-ce/ksqldb-cli/scripts

./utils/create_volumes.sh filepulse kafka-ce/connect/data/filepulse/xml
