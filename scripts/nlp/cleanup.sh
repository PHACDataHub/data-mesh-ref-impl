#!/bin/bash

./scripts/nlp/stop.sh
echo ''

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Shutting down containers...";
docker compose -f docker-compose-nlp.yml down
echo "Containers shutdown ✅";
