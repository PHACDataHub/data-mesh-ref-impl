#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

topic=factiva-articles
no_messages=14

echo Consume messages from ${topic} ...
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)
echo "value_schema_id="$value_schema_id
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --from-beginning --max-messages ${no_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

echo "List of processed article ids (in PostgreSQL)..." 
docker exec -it postgres psql -U postgres -d postgres -c 'SELECT * FROM articles;'
echo ''

topic=summarized-articles
no_messages=5

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)
echo "key_schema_id="$key_schema_id
echo "value_schema_id="$value_schema_id

echo Consume messages from ${topic} ...
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --from-beginning --max-messages ${no_messages} \
    --property print.key=true --property key.separator=" | " \
    --property print.value=true \
    --property value.deserializer=io.confluent.kafka.serializers.KafkaAvroDeserializer  \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''
