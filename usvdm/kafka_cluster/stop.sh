#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

echo "Stopping all services ...";
docker compose down
echo "All services are stopped ✅";
