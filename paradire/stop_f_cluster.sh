#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Shutting down containers...";
docker compose -f docker-compose-f-cluster.yml down
echo "Containers shutdown ✅";
