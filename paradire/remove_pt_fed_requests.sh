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

./scripts/list_plugins.sh
./scripts/list_connectors.sh
./scripts/list_subjects.sh
./scripts/list_topics.sh

event_dir=${curr_dir}/analytics/events

./scripts/delete_connector.sh fed_request_sink_connectors

for request_topic in fed_request_vaccination_record fed_request_zip_immunization fed_request_top_k_immunization fed_request_patient_cvx_org fed_request_city_year_top_proc fed_request_pt_org_med fed_request_city_org_patient fed_request_city_org_patient_visit
# for request_topic in fed_request_vaccination_record
do
    ./scripts/delete_subject.sh ${request_topic}-key
    ./scripts/delete_subject.sh ${request_topic}-value

    ./scripts/delete_topic.sh ${request_topic}
done

for response_topic in fed_response_vaccination_record fed_response_zip_immunization fed_response_top_k_immunization fed_response_patient_cvx_org fed_response_city_year_top_proc fed_response_pt_org_med fed_response_city_org_patient fed_response_city_org_patient_visit
# for response_topic in fed_response_vaccination_record
do
    ./scripts/delete_connector.sh ${response_topic}_source_connector

    ./scripts/delete_subject.sh ${response_topic}-key
    ./scripts/delete_subject.sh ${response_topic}-value

    ./scripts/delete_topic.sh ${response_topic}
done

./scripts/list_connectors.sh
./scripts/list_subjects.sh
./scripts/list_topics.sh

echo 'Removing federated request in the Analytics Pipeline ...'
sudo cp analytics/neo4j/pt_cleanup_fed_requests.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/pt_cleanup_fed_requests.cql
echo 'Constraints and indexes are created ✅'
