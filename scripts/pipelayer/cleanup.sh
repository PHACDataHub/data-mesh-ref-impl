#!/bin/bash

./scripts/pipelayer/stop.sh
echo ''

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Shutting down containers...";
docker compose -f docker-compose-pipelayer.yml down -v
echo "Containers shutdown ✅";
