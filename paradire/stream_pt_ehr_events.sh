#!/bin/bash

valid_pt="AB BC MB NB NL NS NT NU ON PE QC SK YT"

if [ -z "$1" ]; then
    echo "Usage: ./stream_pt_ehr_events.sh <province_or_territory_abbreviation>"
    echo "   where province_or_territory_abbreviation is one of: "
    echo "Example: ./build_image.sh dedup_by_id workflow.yaml main conf/std-requirements.txt conf/avro"
    exit

    exit 1
fi

pt=$1

curr_dir=$(pwd)
cd ~/synthea
data_dir=$(pwd)/

source .env

topic=factiva-articles

avro_dir=${curr_dir}/governance/events
data_dir=${curr_dir}/data
tar_file=factiva_5k_avro.tar.gz
data_file=factiva-articles.txt
no_messages=4825

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

echo "Check if avro is one of supported schema types ...";
supported_types=$(../kafka_cluster/scripts/get_supported_schema_types.sh)
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

./scripts/create_subject.sh ${topic}-key ${avro_dir}/unique-article-key.avsc
./scripts/create_subject.sh ${topic}-value ${avro_dir}/unique-article-val.avsc

./scripts/list_subjects.sh

./scripts/get_subject_info.sh ${topic}-key
./scripts/get_subject_info.sh ${topic}-value

tar xzvf $tar_file -C kafka-ce/schema-registry/data/.

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)

echo "Produce ${no_messages} messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''
