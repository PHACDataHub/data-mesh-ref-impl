#!/bin/bash

# set -e 

curr_dir=$(pwd)

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

event_dir=${curr_dir}/analytics/v2_events
kafka_ce_schema_registry_data_dir=kafka-ce/schema-registry/data
connector_dir=${curr_dir}/analytics/v2_pt_connectors

for item in {1..9}
# for item in $1
do
    request_topic=far_${item}
    echo ${request_topic}

    key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-value/versions/latest | jq .id)

    data_file=${request_topic}.avro
    request_messages=$(cat $event_dir/$data_file | wc -l | tr -d ' ')
    cp $event_dir/${data_file} ${kafka_ce_schema_registry_data_dir}/.

    echo "Produce ${request_messages} messages ..." 
    docker exec ${schema_registry_container} bash -c \
        "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $request_topic --property key.separator='|' --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
    echo ''
done
