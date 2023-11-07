#!/bin/bash

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

event_dir=${curr_dir}/analytics/events
kafka_ce_schema_registry_data_dir=kafka-ce/schema-registry/data
connector_dir=${curr_dir}/analytics/f_connectors

./scripts/list_plugins.sh
./scripts/list_connectors.sh

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

event_dir=${curr_dir}/analytics/events
kafka_ce_schema_registry_data_dir=kafka-ce/schema-registry/data
connector_dir=${curr_dir}/analytics/f_connectors

for request_topic in fed_request_vaccination_record fed_request_zip_immunization fed_request_top_k_immunization fed_request_patient_cvx_org fed_request_city_year_top_proc fed_request_pt_org_med fed_request_city_org_patient fed_request_city_org_patient_visit
# for request_topic in fed_request_vaccination_record
do
    ./scripts/create_topic.sh ${request_topic}

    ./scripts/create_subject.sh ${request_topic}-key ${event_dir}/${request_topic}_key.avsc
    ./scripts/create_subject.sh ${request_topic}-value ${event_dir}/${request_topic}_val.avsc

    ./scripts/get_subject_info.sh ${request_topic}-key
    ./scripts/get_subject_info.sh ${request_topic}-value

    key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${request_topic}-value/versions/latest | jq .id)

    curl -X POST http://${connect_host}:${connect_port}/connectors \
    -H 'Content-Type:application/json' \
    -H 'Accept:application/json' \
    -d @${connector_dir}/${request_topic}_source_connector.json
    echo
done

for response_topic in fed_response_vaccination_record fed_response_zip_immunization fed_response_top_k_immunization fed_response_patient_cvx_org fed_response_city_year_top_proc fed_response_pt_org_med fed_response_city_org_patient fed_response_city_org_patient_visit
# for response_topic in fed_response_vaccination_record
do
    ./scripts/create_topic.sh ${response_topic}

    ./scripts/create_subject.sh ${response_topic}-key ${event_dir}/${response_topic}_key.avsc
    ./scripts/create_subject.sh ${response_topic}-value ${event_dir}/${response_topic}_val.avsc

    ./scripts/get_subject_info.sh ${response_topic}-key
    ./scripts/get_subject_info.sh ${response_topic}-value

    key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${response_topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${response_topic}-value/versions/latest | jq .id)
    echo $key_schema_id $value_schema_id
done

curl -X POST http://${connect_host}:${connect_port}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @${connector_dir}/fed_response_sink_connectors.json
echo

# List the current connector instances
./scripts/list_connectors.sh
