#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

source .env

topic=$1

conf_dir=${curr_dir}/conf
data_dir=${curr_dir}/data
data_file=${topic}.txt

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

./scripts/create_subject.sh ${topic}-value ${conf_dir}/${topic}-value.avsc

./scripts/list_subjects.sh

./scripts/get_subject_info.sh ${topic}-key

./scripts/get_subject_info.sh ${topic}-value

cp $data_dir/$data_file kafka-ce/schema-registry/data/.

./scripts/create_topic.sh ${topic}

cd ${curr_dir}