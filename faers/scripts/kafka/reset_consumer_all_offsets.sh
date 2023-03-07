#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/reset_consumer_all_offsets.sh <consumer-group>";
    exit 1
fi

consumer_group=$1

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

echo "Reset all consumer offsets of filepulse-consumer group ...";
echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
"
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
echo "Consumer offsets reset ✅";
echo ''
