#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./process_fed_request.sh <fed_request_topic>"
    echo "Example: ./process_fed_request.sh fed_request_zip_immunization"
    exit 1
fi

set -e 

source .env

curr_dir=$(pwd)

request_topic=$1

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

avro_dir=${curr_dir}/analytics/neo4j
data_dir=${avro_dir}
kafka_ce_schema_registry_data_dir=${curr_dir}/kafka-ce/schema-registry/data

./scripts/create_subject.sh ${request_topic}-key ${avro_dir}/${request_topic}_key.avsc
./scripts/create_subject.sh ${request_topic}-value ${avro_dir}/${request_topic}_val.avsc

./scripts/get_subject_info.sh ${request_topic}-key
./scripts/get_subject_info.sh ${request_topic}-value

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-value/versions/latest | jq .id)

data_file=${request_topic}.avro
request_messages=$(cat $data_dir/$data_file | wc -l | tr -d ' ')
cp $data_dir/${data_file} ${kafka_ce_schema_registry_data_dir}/.

echo "Produce ${request_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $request_topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''
