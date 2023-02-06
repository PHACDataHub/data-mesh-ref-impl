#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/get_topic_info.sh <topic_name>"
    exit 0
fi

broker=broker:29092
schema_registry=http://schema-registry:8081
localhost_broker=localhost:9092
localhost_schema_registry=localhost:8081

OSTYPE=$(uname -s)

if [[ $OSTYPE == 'Linux' ]]; then
    docker exec kafkacat \
        kafkacat -b ${broker} -t $1 -o-1 \
        -C -J \
        -s key=s -s value=avro -r ${schema_registry} | \
        jq '{"key":.key,"payload": .payload}'
fi
if [[ $OSTYPE == 'Darwin' ]]; then
    kcat -b ${localhost_broker} -t $1 -o-1 \
        -C \
        -s key=s -s value=avro -r ${localhost_schema_registry} 
fi

