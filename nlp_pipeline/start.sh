#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Start all services ...";
docker compose up -d
./scripts/wait_for_kafka.sh
echo "All services have started ✅";
