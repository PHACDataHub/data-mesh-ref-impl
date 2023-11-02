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
connector_dir=${curr_dir}/analytics/connectors

for request_topic in fed_request_vaccination_record fed_request_zip_immunization
do
    ./scripts/create_topic.sh ${request_topic}

    ./scripts/create_subject.sh ${request_topic}-key ${event_dir}/${request_topic}_key.avsc
    ./scripts/create_subject.sh ${request_topic}-value ${event_dir}/${request_topic}_val.avsc

    ./scripts/get_subject_info.sh ${request_topic}-key
    ./scripts/get_subject_info.sh ${request_topic}-value

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

for response_topic in fed_response_vaccination_record fed_response_zip_immunization
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

for response_topic in fed_response_vaccination_record fed_response_zip_immunization
do
    curl -X POST http://${connect_host}:${connect_port}/connectors \
    -H 'Content-Type:application/json' \
    -H 'Accept:application/json' \
    -d @${connector_dir}/${response_topic}_source_connector.json
    echo
done

curl -X POST http://${connect_host}:${connect_port}/connectors \
    -H 'Content-Type:application/json' \
    -H 'Accept:application/json' \
    -d @${connector_dir}/fed_request_sink_connector.json
echo

timeout=10000

for response_topic in fed_response_vaccination_record fed_response_zip_immunization
do
    consumer_group=${response_topic}

    node_label=$(echo ${response_topic:12} | sed 's/.*/\L&/; s/[a-z]*/\u&/g' | sed 's/_//g')
    echo $node_label
    response_messages=$(docker exec --interactive --tty neo4j bash -c "echo 'MATCH (n:$node_label) RETURN COUNT(n) AS c' |  cypher-shell -u $NEO4J_USERNAME -p $NEO4J_PASSWORD  | tail -n 1 | tr -d '\n'")

    echo "Consume up to ${response_messages} messages from ${response_topic} ..." 
    docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --topic ${response_topic} --group ${consumer_group} --from-beginning --max-messages=${response_messages} --timeout-ms ${timeout}\
        --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
    echo ''

    echo Reset all consumer offsets of ${consumer_group} consumer group ...
    echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
    "
    docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
    echo "Consumer offsets reset ✅";
    echo ''
done
