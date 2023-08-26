#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Start all services ...";
docker compose -f docker-compose.yml up -d

./scripts/wait_for_kafka.sh

./scripts/wait_for_it.sh neo4j 60

echo "All services have started ✅";
