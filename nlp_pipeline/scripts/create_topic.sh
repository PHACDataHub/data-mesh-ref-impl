#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/create_topic.sh <topic>";
    exit 1
fi

topic=$1

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}
replication_factor=${REPLICATION_FACTOR}
partitions=${PARTITIONS}

echo "Create topic ${topic} ..." 
echo -e "docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --create --topic ${topic} --partitions ${partitions} --replication-factor ${replication_factor}"

docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --create --topic ${topic} --partitions ${partitions} --replication-factor ${replication_factor}

if [ "$?" = "1" ]; then
    exit 1
fi

echo ${topic} "created ✅";
echo ''
