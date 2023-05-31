#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

source .env

topic=$1
no_messages=$2
consumer_group=$3

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Consume ${no_messages} messages from ${topic} ..." 
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --group ${consumer_group} --from-beginning --max-messages ${no_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

cd ${curr_dir}