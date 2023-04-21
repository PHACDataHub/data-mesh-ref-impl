#!/bin/bash

CURRENT_UID=$(id -u):$(id -g) docker compose down

echo "Pruning docker system ...";
docker system prune -a -f
docker volume rm $(docker volume ls -qf dangling=true)
echo "Docker system pruned ✅";
