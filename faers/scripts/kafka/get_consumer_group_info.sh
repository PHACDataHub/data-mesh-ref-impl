#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/get_consumer_group_info.sh <consumer-group>";
    exit 1
fi

consumer_group=$1

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092

echo "Get ${consumer_group} ...";
echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --describe --group ${consumer_group};
"
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --describe --group ${consumer_group};
echo ''
