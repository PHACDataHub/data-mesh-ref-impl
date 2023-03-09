#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

schema_registry_container=schema-registry
schema_registry_internal_host=schema-registry
schema_registry_local_host=localhost
schema_registry_port=${SCHEMA_REGISTRY_PORT}

postgres_host=postgres
postgres_port=${POSTGRES_PORT}
postgres_user=${POSTGRES_USER}
postgres_pass=${POSTGRES_PASSWORD}
composite_keys=link,pub_date

topic=screenrant-named-entity-recognizer-topic,screenrant-question-answer-topic,screenrant-sentiment-analyzer-topic,screenrant-summarizer-topic
connector=postgres-sink

./scripts/kafka/list_plugins.sh
./scripts/kafka/list_connectors.sh
./scripts/kafka/list_subjects.sh

echo "Create database screenrant ...";
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE DATABASE screenrant;' 
echo "Database screenrant created ✅";
echo ''

echo "Create table rss ...";
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE TABLE rss(category VARCHAR, classified_labels VARCHAR, content VARCHAR, creator VARCHAR, description VARCHAR, enclosure_url VARCHAR, full_text VARCHAR, href_list VARCHAR, link VARCHAR, named_entities VARCHAR, question_answer VARCHAR, pub_date VARCHAR, sentiment_score VARCHAR, summary_text VARCHAR, timestamp_ne INT, timestamp_qa INT, timestamp_sa INT, timestamp_sm INT, timestamp_tc INT, title VARCHAR, PRIMARY KEY(link, pub_date));' 
echo "Table rss created ✅";
echo ''

echo "Creating posrgres sink connector ...";
curl -X PUT http://${connect_local_host}:${connect_port}/connectors/${connector}/config \
    -H "Content-Type: application/json" \
    -d '{
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "connection.url": "jdbc:postgresql://'${postgres_host}':'${postgres_port}'/",
        "connection.user": "'${postgres_user}'",
        "connection.password": "'${postgres_pass}'",
        "tasks.max": "1",
        "topics": "'${topic}'",
        "auto.create": "true",
        "auto.evolve":"false",
        "pk.mode":"record_value",
        "pk.fields":"'${composite_keys}'",
        "insert.mode": "upsert",
        "table.name.format":"rss"
    }'
echo ''
echo "Postgres sink connector created ✅";
echo ''
