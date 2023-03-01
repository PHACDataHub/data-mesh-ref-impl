#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092
connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083
schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=8081

key_fields_counties=county_fips
cast_types_counties=population:int32,lat:float32,lng:float32
no_messages=10
topic_spooldir=topic-counties
connector_spooldir=spooldir-counties

postgres_host=postgres
postgres_port=5432
postgres_user=postgres
postgres_pass=postgres
composite_keys=county_fips
connector_sink=sink-postgres

echo "Listing all available plugins ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins |jq '.[].class'
echo ''

echo "Listing all connectors ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo 'Copying data into for spooldir ...'
for item in counties
do
    cp data/kafka-ce/${item}.csv kafka-ce/connect/data/spooldir/unprocessed/${item}-$RANDOM.csv;
    echo data/kafka-ce/${item}.csv 'is copied.'
done
echo 'Folders for spooldir data created ✅'
echo ''

for item in counties
do
    key_fields_var="key_fields_"${item}
    key_fields="${!key_fields_var}"
    cast_types_var="cast_types_"${item}
    cast_types="${!cast_types_var}"
    echo ${item} ${key_fields} ${cast_types}

    curl -i -X PUT -H "Accept:application/json" \
        -H  "Content-Type:application/json" http://${connect_local_host}:${connect_port}/connectors/${connector_spooldir}/config \
        -d '{
            "connector.class":"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
            "topic":"'${topic_spooldir}'",
            "input.path":"/data/spooldir/unprocessed",
            "finished.path":"/data/spooldir/processed",
            "error.path":"/data/spooldir/error",
            "input.file.pattern":"^'${item}'-[0-9]+\\.csv",
            "schema.generation.enabled":"true",
            "schema.generation.key.fields":"'${key_fields}'",
            "csv.first.row.as.header":"true",
            "transforms":"castTypes",
            "transforms.castTypes.type":"org.apache.kafka.connect.transforms.Cast$Value",
            "transforms.castTypes.spec":"'${cast_types}'"
            }'
    echo ''
    echo ''
done

echo "Wait for delivery ..." 
sleep 3
echo ''

echo "Listing all connectors ...";
curl -s -X GET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo "List all topics ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "List all versions of ${topic_spooldir}-key..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-key/versions/latest | jq
echo ''

echo "List all versions of ${topic_spooldir}-value..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-value/versions/latest | jq
echo ''

key_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-key/versions/latest | jq .id)
value_schema_id=$(curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-value/versions/latest | jq .id)

echo "Consume messages ..." 
docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic_spooldir} --from-beginning --max-messages ${no_messages} \
    --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
echo ''

echo "Start postgres ...";
docker compose -f docker-compose-postgres.yml up -d
echo ''

echo "Wait for postgres ready ..." 
sleep 3
echo ''

echo "Creating posrgres sink connector ...";
curl -X PUT http://${connect_local_host}:${connect_port}/connectors/${connector_sink}/config \
    -H "Content-Type: application/json" \
    -d '{
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "connection.url": "jdbc:postgresql://'${postgres_host}':'${postgres_port}'/",
        "connection.user": "'${postgres_user}'",
        "connection.password": "'${postgres_pass}'",
        "tasks.max": "1",
        "topics": "'${topic_spooldir}'",
        "auto.create": "true",
        "auto.evolve":"true",
        "pk.mode":"record_value",
        "pk.fields":"'${composite_keys}'",
        "insert.mode": "upsert",
        "table.name.format":"'${topic_spooldir}'"
    }'
echo ''
echo "Postgres sink connector created ✅";
echo ''

echo "Wait for delivery ..." 
sleep 3
echo ''

echo "Listing all connectors ...";
curl -s -X GET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo "Verifying database records ...";
docker exec -it postgres psql -U postgres -d postgres -c 'SELECT * FROM "topic-counties";' 
echo "Database records verified ✅";
echo ''

echo "Delete database records ...";
docker exec -it postgres psql -U postgres -d postgres -c 'DELETE FROM "topic-counties";'
echo "Database records deleted ✅";
echo ''

echo "Shutting down postgres ...";
docker compose -f docker-compose-postgres.yml down
echo "Postgres shutdown ✅";

echo "Delete ${topic_spooldir}-key subject ..." 
curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-key | jq .[]
echo ''

echo "Delete ${topic_spooldir}-value subject ..." 
curl --silent -X DELETE http://${schema_registry_local_host}:${schema_registry_port}/subjects/${topic_spooldir}-value | jq .[]
echo ''

echo "List all current subjects ..." 
curl --silent -X GET http://${schema_registry_local_host}:${schema_registry_port}/subjects | jq .[]
echo ''

echo "Delete connector ..." 
curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector_spooldir} | jq .[]
echo ${connector_spooldir} "connector deleted ✅";

echo "Delete connector ..." 
curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector_sink} | jq .[]
echo ${connector_sink} "connector deleted ✅";

echo "Deleting ${topic_spooldir} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --delete --topic ${topic_spooldir} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port}
echo ${topic_spooldir} "deleted ✅";
echo ''

echo "List all topics ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''

echo "Removing processed data from spooldir ...";
sudo rm -rf kafka-ce/connect/data/spooldir/processed/counties-*.csv;
echo "Processed data in spooldir deleted ✅";