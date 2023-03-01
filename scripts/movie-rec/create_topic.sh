#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/create_topic.sh <topic>";
    exit 1
fi

topic=$1

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092

echo "Create topic ${topic} ..." 
echo -e "docker exec -it ${broker_container_name} /bin/kafka-topics \
    --create --topic ${topic_filepulse} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port}"
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --create  --topic ${topic} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port}

if [ "$?" = "1" ]; then
    exit 1
fi

echo ${topic} "created ✅";
echo ''
