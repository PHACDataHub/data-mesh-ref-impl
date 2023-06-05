#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

source .env

topic=$1

conf_dir=${curr_dir}/conf
data_dir=${curr_dir}/data
data_file=${topic}.txt
no_messages=$(cat $data_dir/$data_file | wc -l | tr -d ' ')

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Check if avro is one of supported schema types ...";
supported_types=$(./scripts/get_supported_schema_types.sh)
echo $supported_types "are supported ✅";
if [ -z "$(echo $supported_types} | grep AVRO)" ]; then
    echo 'AVRO is not supported ❌'
    exit 1
else
    echo 'AVRO is supported ✅'
fi
echo ''

./scripts/get_schema_registry_config.sh

./scripts/list_subjects.sh

./scripts/create_subject.sh ${topic}-key ${conf_dir}/${topic}-key.avsc

./scripts/create_subject.sh ${topic}-value ${conf_dir}/${topic}-val.avsc

./scripts/list_subjects.sh

./scripts/get_subject_info.sh ${topic}-key

./scripts/get_subject_info.sh ${topic}-value

cp $data_dir/$data_file kafka-ce/schema-registry/data/.

./scripts/create_topic.sh ${topic}

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)

echo "Produce ${no_messages} messages for ${topic} ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''

cd ${curr_dir}