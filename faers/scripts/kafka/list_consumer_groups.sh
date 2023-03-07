#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

echo "All current consumer groups ...";
echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --list;
"
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --list;
echo ''
