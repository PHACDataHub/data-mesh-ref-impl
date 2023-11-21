#!/bin/bash

# Generate sample data
./genenerate_pt_sampling.sh $sampling_size /data $pt

# Upload sample data to FHIR server
./upload_FHIR_data.sh /data $pt $fihr_server_url

# Convert CSV data into avro messages
python ./csv2avro.py /workspace/governance/events "$(realpath /data/$pt/csv/*/)" "$(realpath /data/$pt/symptoms/csv/*/)" /data

# Set current working directory and other configurations
avro_dir="/workspace/governance/events"
data_dir="/data"

# Define Kafka and Schema Registry related variables
# These are now expected to be provided as environment variables

connect_url="${CONNECT_URL}"
schema_url="${SCHEMA_URL}"
broker_url="${BROKER_URL}"

# Check for required environment variables
if [ -z "$CONNECT_URL" ] || [ -z "$SCHEMA_URL" ] || [ -z "$BROKER_URL" ] ; then
    echo "Error: Required environment variables are not set."
    exit 1
fi


# Function to get supported schema types
get_supported_schema_types() {
    curl --silent ${schema_url}/schemas/types
}


# Create a subject
create_subject() {
    if [ "$#" -ne 2 ]; then
        echo "Usage ./scripts/create_subject.sh <subject> <schema_file>";
        exit 1
    fi

    local subject=$1
    local schema_file=$2

    echo "Creating subject ${subject} with schema ${schema_file} ..." 
    local escaped_avsc=$(cat $schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
    escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})
    curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data "$escaped_avsc" \
        ${schema_url}/subjects/${subject}/versions | jq .[]
    echo ''
}

# Function to get subject information
get_subject_info() {

    local subject=$1

    echo "Find ID of the ${subject}..." 
    local schema_id=$(curl --silent -X GET ${schema_url}/subjects/${subject}/versions/latest | jq .id)
    echo schema_id=${schema_id}
    echo ''
    echo ''

    echo "Find details of the ${subject}..." 
    curl --silent -X GET ${schema_url}/subjects/${subject}/versions/latest
    echo ''
    echo ''

    echo "List all versions of ${subject}..." 
    curl --silent -X GET ${schema_url}/subjects/${subject}/versions | jq
    echo ''
}

# Check if AVRO is a supported schema type
echo "Checking if AVRO is a supported schema type..."
supported_types=$(get_supported_schema_types)
echo "Supported types: ${supported_types} ✅"
if [[ ! $supported_types =~ "AVRO" ]]; then
    echo 'AVRO is not supported ❌'
    exit 1
else
    echo 'AVRO is supported ✅'
fi
echo ''


# Define the topics to process
topics=(allergies careplans claims claims_transactions conditions devices encounters imaging_studies immunizations medications observations organizations patient_expenses patients payer_transitions payers procedures providers supplies symptoms)

# Process each topic
for topic in "${topics[@]}"; do
    create_subject "${topic}-key" "${avro_dir}/${topic}_key.avsc"
    create_subject "${topic}-value" "${avro_dir}/${topic}_val.avsc"

    get_subject_info "${topic}-key"
    get_subject_info "${topic}-value"

    # Retrieve Schema IDs for both key and value
    key_schema_id=$(curl --silent -X GET "${schema_url}/subjects/${topic}-key/versions/latest" | jq .id)
    value_schema_id=$(curl --silent -X GET "${schema_url}/subjects/${topic}-value/versions/latest" | jq .id)

    # Prepare data file and count the number of messages
    data_file="${data_dir}/${topic}.avro"
    no_messages=$(wc -l < "${data_file}" | tr -d ' ')

    echo "Producing ${no_messages} messages for topic ${topic}..."
    kafka-avro-console-producer --broker-list ${broker_url} --topic ${topic} --property schema.registry.url=${schema_url} --property key.separator='|' --property parse.key=true --property key.schema.id=${key_schema_id} --property value.schema.id=${value_schema_id} < ${data_file}
    echo ''

done

gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
gsutil -m cp -r /data/* gs://${GCS_BUCKET}/$pt/$(date +%Y%m%d-%H%M%S)/
echo "Data upload to GCS completed."