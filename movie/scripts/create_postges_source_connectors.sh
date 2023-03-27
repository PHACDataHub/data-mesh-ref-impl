#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

postgres_host=postgres
postgres_port=${POSTGRES_PORT}
postgres_user=${POSTGRES_USER}
postgres_pass=${POSTGRES_PASSWORD}
composite_keys=link,pub_date

topic=analyst-
connector=postgres-source

./scripts/kafka/list_plugins.sh
./scripts/kafka/list_connectors.sh
./scripts/kafka/list_subjects.sh

echo "Creating posrgres source connector ...";
curl -X PUT http://${connect_host}:${connect_port}/connectors/${connector}/config \
    -H "Content-Type: application/json" \
    -d '{
        "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url": "jdbc:postgresql://'${postgres_host}':'${postgres_port}'/",
        "connection.user": "'${postgres_user}'",
        "connection.password": "'${postgres_pass}'",
        "tasks.max": "1",
        "topic.prefix": "'${topic}'",
        "mode":"incrementing",
        "table.whitelist":"decision",
        "incrementing.column.name":"id"
    }'
echo ''
echo "Postgres source connector created ✅";
echo ''
