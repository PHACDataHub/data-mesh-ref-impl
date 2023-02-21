#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage ./scripts/movie-rec/consume_messages.sh <topic> <timeout_ms> <consumer-group>";
    exit 1
fi

topic=$1
timeout_ms=$2
consumer_group=$3

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=8081

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

echo "Consume messages ..." 
echo "docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --group ${consumer_group} --from-beginning --timeout-ms ${timeout_ms} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
"
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --group ${consumer_group} --from-beginning  --timeout-ms ${timeout_ms} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''
