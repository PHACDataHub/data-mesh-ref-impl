#!/bin/bash

# Generate sample data
./genenerate_pt_sampling.sh $sampling_size /data $pt

# Upload sample data to FHIR server
./upload_FHIR_data.sh /data $pt $fihr_server_url

# Convert CSV data into avro messages
python ./csv2avro.py /workspace/governance/events "$(realpath /data/$pt/csv/*/)" "$(realpath /data/$pt/symptoms/csv/*/)" /data

# Create subjects (key/value) based on avro schemas

# topics=(allergies careplans claims claims_transactions conditions devices encounters imaging_studies immunizations medications observations organizations patient_expenses patients payer_transitions payers procedures providers supplies symptoms)
# # Process each topic
# for topic in "${topics[@]}"; do

#     ## DO THIS TWICE
#     # "${topic}-key" "${avro_dir}/${topic}_key.avsc"

#     echo "Creating subject ${subject} with schema ${schema_file} ..." 
#     escaped_avsc=$(cat $schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
#     escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})

#     curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
#         --data "$escaped_avsc" \
#         http://${schema_registry_host}:${schema_registry_port}/subjects/${subject}/versions | jq .[]

#     # "${topic}-value" "${avro_dir}/${topic}_val.avsc"

#     echo "Creating subject ${subject} with schema ${schema_file} ..." 
#     escaped_avsc=$(cat $schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
#     escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})

#     curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
#         --data "$escaped_avsc" \
#         http://${schema_registry_host}:${schema_registry_port}/subjects/${subject}/versions | jq .[]

   
#     ### end of creating subjects

#     # Retrieve Schema IDs for both key and value
#     key_schema_id=$(curl --silent -X GET "http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-key/versions/latest" | jq .id)
#     value_schema_id=$(curl --silent -X GET "http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic}-value/versions/latest" | jq .id)


# done