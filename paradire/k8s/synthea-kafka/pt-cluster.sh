#!/bin/bash

for i in {1..10}
do
   echo "Running PT CLUSTER JOB"
done

# Generate sample data
./genenerate_pt_sampling.sh $sampling_size /data $pt

# Upload sample data to FHIR server
./upload_FHIR_data.sh /data $pt $fihr_server_url

# Convert CSV data into avro messages
python ./csv2avro.py /workspace/governance/events "$(realpath /data/$pt/csv/*/)" "$(realpath /data/$pt/symptoms/csv/*/)" /data

# Set current working directory and other configurations
avro_dir="/workspace/governance/events"
data_dir="/data"
event_dir="/workspace/analytics/v2_events"
connector_pt_dir="/workspace/analytics/v2_pt_connectors"

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

# Function to list all available plugins
list_plugins() {
    echo "All available plugins ...";
    curl -s -XGET ${connect_url}/connector-plugins | jq '.[].class'
    echo ''
}

# Function to list all current connectors
list_connectors() {
    echo "All current connectors ...";
    curl -s -XGET ${connect_url}/connectors | jq '.[]'
    echo ''
}

# Function to get schema registry configuration
get_schema_registry_config() {
    echo "Top level schema compatibility configuration ..." 
    curl --silent -X GET ${schema_url}/config | jq .[]
    echo ''
}

# Function to get supported schema types
get_supported_schema_types() {
    curl --silent ${schema_url}/schemas/types
}

# Function to list all current subjects
list_subjects() {
    echo "List all current subjects ..." 
    curl --silent -X GET ${schema_url}/subjects | jq .[]
    echo ''
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


# Create request and response topics and subjects
for item in {1..9}; do
    request_topic=far_${item}

    create_subject ${request_topic}-key ${event_dir}/${request_topic}_key.avsc
    create_subject ${request_topic}-value ${event_dir}/${request_topic}_val.avsc
    get_subject_info ${request_topic}-key
    get_subject_info ${request_topic}-value

    key_schema_id=$(curl --silent -X GET ${schema_url}/subjects/${request_topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET ${schema_url}/subjects/${request_topic}-value/versions/latest | jq .id)
done


for item in {1..9}; do
    response_topic=fas_${item}

    create_subject ${response_topic}-key ${event_dir}/${response_topic}_key.avsc
    create_subject ${response_topic}-value ${event_dir}/${response_topic}_val.avsc
    get_subject_info ${response_topic}-key
    get_subject_info ${response_topic}-value

    key_schema_id=$(curl --silent -X GET ${schema_url}/subjects/${response_topic}-key/versions/latest | jq .id)
    value_schema_id=$(curl --silent -X GET ${schema_url}/subjects/${response_topic}-value/versions/latest | jq .id)
    echo $key_schema_id $value_schema_id
done

# Create connectors for response topics
for item in {1..9}; do
    response_topic=fas_${item}
    
    curl -X POST ${connect_url}/connectors \
    -H 'Content-Type:application/json' \
    -H 'Accept:application/json' \
    -d @${connector_pt_dir}/${response_topic}_source_connector.json
    echo
done

# Create sink connector
curl -X POST ${connect_url}/connectors \
    -H 'Content-Type:application/json' \
    -H 'Accept:application/json' \
    -d @${connector_pt_dir}/far_sink_connectors.json
echo ''

# Additional Connector Creation
echo "Creating additional connectors..."

# Create the first event sink connector
curl -X POST ${connect_url}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @${connector_pt_dir}/event_sink_connector_1.json
echo

# List the current connector instances
list_connectors

echo "Wait for sinking key entities"
sleep 10

# Create the second event sink connector
curl -X POST ${connect_url}/connectors \
  -H 'Content-Type:application/json' \
  -H 'Accept:application/json' \
  -d @${connector_pt_dir}/event_sink_connector_2.json
echo

# List the current connector instances again
list_connectors

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

# List the current Schema Registry configuration and subjects
get_schema_registry_config
list_subjects

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

# List subjects at the end of the script
list_subjects


gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
gsutil -m cp -r /data/* gs://${GCS_BUCKET}/$pt/$(date +%Y%m%d-%H%M%S)/
echo "Data upload to GCS completed."