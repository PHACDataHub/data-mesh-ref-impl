#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/restart_service.sh <service>";
    exit 1
fi

service=$1

echo "Restart service ${service}...";
docker compose -f docker-compose-kafka-ce.yml restart ${service}
./scripts/kafka/wait_for_services.sh
echo "Service ${service} restarted ✅";
