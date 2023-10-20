#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./stream_pt_ehr_events.sh <data_dir>"
    echo "   where data_dir would be, e.g.: "
    echo "Example: ./stream_pt_ehr_events.sh ~/synthea/ca_spp/SK/avro/2023_10_17T22_19_30Z"
    exit 1
fi

set -e

curr_dir=$(pwd)
avro_dir=${curr_dir}/governance/events
data_dir=$1

source .env

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

for topic in allergies careplans claims claims_transactions conditions devices encounters imaging_studies immunizations medications observations organizations patient_expenses patients payer_transitions payers procedures providers supplies
do
    ./scripts/create_subject.sh ${topic}-key ${avro_dir}/${topic}_key.avsc
    ./scripts/create_subject.sh ${topic}-value ${avro_dir}/${topic}_val.avsc

    ./scripts/get_subject_info.sh ${topic}-key
    ./scripts/get_subject_info.sh ${topic}-value

    key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest | jq .id)

    data_file=${topic}.avro
    no_messages=$(cat $data_dir/$data_file | wc -l | tr -d ' ')

    echo "Produce ${no_messages} messages ..." 
    docker exec ${schema_registry_container} bash -c \
        "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
    echo ''
done

./scripts/list_subjects.sh