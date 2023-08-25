#!/bin/bash

if [ $# -lt 6 ]; then
    echo "Usage: ./produce_messages.sh <TOPIC_NAME> <TAR_FILE> <DATA_FILE> <NUMBER_OF_MESSAGES> <AVRO_KEY> <AVRO_VAL>"
    echo 
    echo "Example: ./produce_messages.sh who-don-articles data/who/who_dons.tar.gz who_dons-1-142.txt 2836 who-don-key who-don-val"
    exit
fi

# TOPIC_NAME: who-don-articles
# TAR_FILE: data/who/who_dons.tar.gz
# DATA_FILE: who_dons-1-142.txt
# NUMBER_OF_MESSAGES: 2836
# AVRO_KEY: who-don-key
# AVRO_VAL: who-don-val
TOPIC_NAME=$1
TAR_FILE=$2
DATA_FILE=$3
NUMBER_OF_MESSAGES=$4
AVRO_KEY=$5
AVRO_VAL=$6

curr_dir=$(pwd)

source .env

topic=${TOPIC_NAME}

avro_dir=${curr_dir}/conf/avro
tar_file=${curr_dir}/${TAR_FILE}
data_file=${DATA_FILE}
no_messages=${NUMBER_OF_MESSAGES}

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

./scripts/create_subject.sh ${topic}-key ${avro_dir}/${AVRO_KEY}.avsc
./scripts/create_subject.sh ${topic}-value ${avro_dir}/${AVRO_VAL}.avsc

./scripts/list_subjects.sh

./scripts/get_subject_info.sh ${topic}-key
./scripts/get_subject_info.sh ${topic}-value

tar xzvf $tar_file -C kafka-ce/schema-registry/data/.

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)

echo "Produce ${no_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_host:$broker_external_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''
