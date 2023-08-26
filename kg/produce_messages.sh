#!/bin/bash

curr_dir=$(pwd)

source .env

broker_container_name=broker
broker_host=broker
broker_external_port=${BROKER_EXTERNAL_PORT}
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

TOPIC_NAME=incoming-articles
AVRO_KEY=incoming-article-key
AVRO_VAL=incoming-article-val

topic=${TOPIC_NAME}
avro_dir=${curr_dir}/conf/avro

./scripts/create_subject.sh ${topic}-key ${avro_dir}/${AVRO_KEY}.avsc
./scripts/create_subject.sh ${topic}-value ${avro_dir}/${AVRO_VAL}.avsc

./scripts/list_subjects.sh

./scripts/get_subject_info.sh ${topic}-key
./scripts/get_subject_info.sh ${topic}-value

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)

TAR_FILE=data/do-classes.tar.gz
DATA_FILE=do-classes.txt
NUMBER_OF_MESSAGES=13843

tar_file=${curr_dir}/${TAR_FILE}
data_file=${DATA_FILE}
no_messages=${NUMBER_OF_MESSAGES}

tar xzvf $tar_file -C kafka-ce/schema-registry/data/.

echo "Produce ${no_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_host:$broker_external_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''

TAR_FILE=data/who_dons.tar.gz
DATA_FILE=who_dons-1-142.txt
NUMBER_OF_MESSAGES=2836

tar_file=${curr_dir}/${TAR_FILE}
data_file=${DATA_FILE}
no_messages=${NUMBER_OF_MESSAGES}

tar xzvf $tar_file -C kafka-ce/schema-registry/data/.

echo "Produce ${no_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_host:$broker_external_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''