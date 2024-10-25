#!/bin/bash

source .env

topic=daily-report

conf_dir=./scripts/tests/conf
data_dir=./scripts/tests/data
data_file=${topic}-data.txt
no_messages=12

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_host=${SCHEMA_REGISTRY_HOST}
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Check if avro is one of supported schema types ...";
supported_types=$(./scripts/kafka/get_supported_schema_types.sh)
echo $supported_types "are supported ✅";
if [ -z "$(echo $supported_types} | grep AVRO)" ]; then
    echo 'AVRO is not supported ❌'
    exit 1
else
    echo 'AVRO is supported ✅'
fi
echo ''

./scripts/kafka/get_schema_registry_config.sh

./scripts/kafka/list_subjects.sh

./scripts/kafka/create_subject.sh ${topic}-key ${conf_dir}/${topic}-key.avsc


./scripts/kafka/create_subject.sh ${topic}-value ${conf_dir}/${topic}-value.avsc

./scripts/kafka/list_subjects.sh

./scripts/kafka/get_subject_info.sh ${topic}-key

./scripts/kafka/get_subject_info.sh ${topic}-value

cp $data_dir/$data_file kafka-ce/schema-registry/data/.

./scripts/kafka/create_topic.sh ${topic}

key_schema_id=$(curl --silent -X GET http://${schema_registry_host}:${schema_registry_port}/subjects/daily-report-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_host}:${schema_registry_port}/subjects/daily-report-value/versions/latest | jq .id)

echo "Produce ${no_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $topic --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''

echo "Consume messages ..." 
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --from-beginning --max-messages ${no_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

./scripts/kafka/delete_subject.sh ${topic}-key

./scripts/kafka/delete_subject.sh ${topic}-value

./scripts/kafka/list_subjects.sh

./scripts/kafka/delete_topic.sh ${topic}

rm kafka-ce/schema-registry/data/$data_file
