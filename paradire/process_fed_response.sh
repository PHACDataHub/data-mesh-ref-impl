#!/bin/bash

set -e 

source .env

curr_dir=$(pwd)

response_topic=$1
response_messages=$2
consumer_group=fed_response_zip_immunization_consumer_group

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Consume ${response_messages} messages from ${response_topic} ..." 
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${response_topic} --group ${consumer_group} --from-beginning --max-messages ${response_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

echo Reset all consumer offsets of ${consumer_group} consumer group ...
echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
"
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
echo "Consumer offsets reset ✅";
echo ''