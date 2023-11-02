#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/get_topic_info.sh <topic>";
    exit 1
fi

topic=$1

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

echo "Aboout topic ${topic} ..." 
echo -e "docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --describe --topic ${topic}"

docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --describe --topic ${topic}

if [ "$?" = "1" ]; then
    exit 1
fi

echo ''
