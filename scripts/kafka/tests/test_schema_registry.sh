#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

topic_avro=daily-report
schema_dir=conf/kafka-ce
data_dir=data/kafka-ce
schema_key_avsc=${topic_avro}-key.avsc
schema_value_avsc=${topic_avro}-value.avsc
data_file=${topic_avro}-data.txt
no_messages=12

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092
schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=8081

echo "Create ${topic_avro} from inside ${broker_container_name} to ${broker_internal_host}:${broker_internal_port} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --create --topic ${topic_avro} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port};
echo "${topic_avro} created ✅";
echo ''

echo "Check schema types are supported by http://${schema_registry_local_host}:${schema_registry_port} ...";
supported_types=$(curl --silent http://${schema_registry_local_host}:${schema_registry_port}/schemas/types)
echo $supported_types "are supported ✅";
if [ -z "$(echo $supported_types} | grep AVRO)" ]; then
    echo 'AVRO is not supported ❌'
    exit 1
else
    echo 'AVRO is supported ✅'
fi
echo ''

echo "Get top level schema compatibility configuration ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/config | jq .[]
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "Add key schema for daily reports ..." 
escaped_avsc=$(cat $schema_dir/$schema_key_avsc | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})
curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "$escaped_avsc" \
    http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-key/versions | jq .[]
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "Add value schema for daily reports ..." 
escaped_avsc=$(cat $schema_dir/$schema_value_avsc | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )
escaped_avsc=$(echo {\"schema\": \"$escaped_avsc\"})
curl --silent -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "$escaped_avsc" \
    http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-value/versions | jq .[]
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "List all versions of daily-report-key..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-key/versions/latest | jq
echo ''

echo "List all versions of daily-report-value..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-value/versions/latest | jq
echo ''

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-value/versions/latest | jq .id)

cp $data_dir/$data_file vol/schema-registry/data/.

echo "Produce messages ..." 
docker exec ${schema_registry_container} bash -c \
    "kafka-avro-console-producer  --broker-list $broker_internal_host:$broker_internal_port --topic $topic_avro --property parse.key=true --property key.schema.id=$key_schema_id --property value.schema.id=$value_schema_id < /data/$data_file"
echo ''

rm vol/schema-registry/data/$data_file

echo "Consume messages ..." 
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic_avro} --from-beginning --max-messages ${no_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

echo "Delete daily-report-key subject ..." 
curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-key | jq .[]
echo ''

echo "Delete daily-report-value subject ..." 
curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/daily-report-value | jq .[]
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "Deleting ${topic_avro} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --delete --topic ${topic_avro} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port}
echo ${topic_avro} "deleted ✅";
