#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092

echo "List all topics ...";
echo docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''
