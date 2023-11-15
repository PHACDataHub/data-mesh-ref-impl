#!/bin/bash

# Check if a data directory is provided or use 'data' as the default
if [ -z "$1" ]; then
    if [ -d "data" ]; then
        data_dir="data"
    else
        echo "Usage: ./stream_pt_ehr_events.sh <data_dir>"
        echo "   where data_dir would be, e.g.: "
        echo "Example: ./stream_pt_ehr_events.sh data"
        exit 1
    fi
else
    data_dir="$1"
fi

# Set current working directory and other configurations
curr_dir=$(pwd)
avro_dir="${curr_dir}/governance/events"
kafka_ce_schema_registry_data_dir="kafka-ce/schema-registry/data"
source .env

# Define Kafka and Schema Registry related variables
broker_container_name="broker"
broker_internal_host="broker"
broker_internal_port="${BROKER_INTERNAL_PORT}"

schema_registry_container="schema-registry"
schema_registry_local_host="localhost"
schema_registry_port="${SCHEMA_REGISTRY_PORT}"

echo "Checking if AVRO is a supported schema type..."
supported_types=$(./scripts/get_supported_schema_types.sh)
echo "Supported types: ${supported_types} ✅"
if [[ ! $supported_types =~ "AVRO" ]]; then
    echo 'AVRO is not supported ❌'
    exit 1
else
    echo 'AVRO is supported ✅'
fi
echo ''

# List the current Schema Registry configuration and subjects
./scripts/get_schema_registry_config.sh
./scripts/list_subjects.sh

# Define the topics to process
topics=(allergies careplans claims claims_transactions conditions devices encounters imaging_studies immunizations medications observations organizations patient_expenses patients payer_transitions payers procedures providers supplies symptoms)

# Process each topic
for topic in "${topics[@]}"; do
    ./scripts/create_topic.sh "${topic}"

    ./scripts/create_subject.sh "${topic}-key" "${avro_dir}/${topic}_key.avsc"
    ./scripts/create_subject.sh "${topic}-value" "${avro_dir}/${topic}_val.avsc"

    ./scripts/get_subject_info.sh "${topic}-key"
    ./scripts/get_subject_info.sh "${topic}-value"

    # Retrieve Schema IDs for both key and value
    key_schema_id=$(curl --silent -X GET "http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest" | jq .id)
    value_schema_id=$(curl --silent -X GET "http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest" | jq .id)

    # Prepare data file and count the number of messages
    data_file="${data_dir}/${topic}.avro"
    no_messages=$(wc -l < "${data_file}" | tr -d ' ')
    mv "${data_file}" "${kafka_ce_schema_registry_data_dir}/."

    echo "Producing ${no_messages} messages for topic ${topic}..."
    docker exec "${schema_registry_container}" bash -c \
        "kafka-avro-console-producer --broker-list ${broker_internal_host}:${broker_internal_port} --topic ${topic} --property key.separator='|' --property parse.key=true --property key.schema.id=${key_schema_id} --property value.schema.id=${value_schema_id} < /data/${topic}.avro"
    echo ''

    # Move the data file back to its original directory
    mv "${kafka_ce_schema_registry_data_dir}/${topic}.avro" "${data_dir}/."
done

# List subjects at the end of the script
./scripts/list_subjects.sh
