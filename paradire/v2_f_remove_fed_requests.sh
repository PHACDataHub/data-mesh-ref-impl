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

event_dir=${curr_dir}/analytics/v2_events

# for item in {1..9}
for item in $1
do
    request_topic=far_${item}

    ./scripts/delete_connector.sh ${request_topic}_source_connector

    ./scripts/delete_subject.sh ${request_topic}-key
    ./scripts/delete_subject.sh ${request_topic}-value

    ./scripts/delete_topic.sh ${request_topic}
done

./scripts/delete_connector.sh fas_sink_connectors

# for item in {1..9}
for item in $1
do
    response_topic=fas_${item}

    ./scripts/delete_subject.sh ${response_topic}-key
    ./scripts/delete_subject.sh ${response_topic}-value

    ./scripts/delete_topic.sh ${response_topic}
done

./scripts/list_connectors.sh
./scripts/list_subjects.sh
./scripts/list_topics.sh

echo 'Removing federated request in the Analytics Pipeline ...'
sudo cp analytics/v2_neo4j/v2_cleanup_entities.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/v2_cleanup_entities.cql
echo 'Constraints and indexes are created ✅'
