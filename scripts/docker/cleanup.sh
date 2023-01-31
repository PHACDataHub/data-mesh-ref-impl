#!/bin/bash

CURRENT_UID=$(id -u):$(id -g) docker compose down

echo "Pruning docker system ...";
docker system prune -a -f
echo "Docker system pruned ✅";
