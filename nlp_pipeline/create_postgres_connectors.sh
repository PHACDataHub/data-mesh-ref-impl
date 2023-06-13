#!/bin/bash

echo "Create table articles ...";
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE TABLE IF NOT EXISTS articles(doc_id TEXT PRIMARY KEY);' 
echo "Table articles created ✅";
echo ''

echo "Create table embeddings ...";
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE TABLE IF NOT EXISTS embeddings(doc_id TEXT PRIMARY KEY, para_lengths INTEGER[], pickled BYTEA, timestamp BIGINT);' 
echo "Table embeddings created ✅";
echo ''

./scripts/list_plugins.sh
./scripts/list_connectors.sh
./scripts/list_subjects.sh

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
postgres_database=postgres

sink_connector=pending-review
sink_topic=pending-review-articles
sink_pk_fields=doc_id
sink_table=pending_review

echo Create table ${sink_table} ...;
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE TABLE IF NOT EXISTS '${sink_table}'(doc_id TEXT PRIMARY KEY, folder TEXT, headline TEXT, lead_para TEXT[], tail_para TEXT[], lang_id TEXT, lang_name TEXT, labels TEXT, bio_ner TEXT, ner TEXT, summary_text TEXT, is_reviewed BOOLEAN DEFAULT FALSE);' 
echo Table ${sink_table} created ✅;
echo ''

echo Creating Posrgres sink connector ${sink_connector} for topic ${sink_topic} ...;
curl -X PUT http://${connect_host}:${connect_port}/connectors/${sink_connector}/config \
    -H "Content-Type: application/json" \
    -d '{
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "connection.url": "jdbc:postgresql://'${postgres_host}':'${postgres_port}'/",
        "connection.user": "'${postgres_user}'",
        "connection.password": "'${postgres_pass}'",
        "tasks.max": "1",
        "topics": "'${sink_topic}'",
        "auto.create": "true",
        "auto.evolve":"false",
        "pk.mode":"record_key",
        "pk.fields":"'${sink_pk_fields}'",
        "insert.mode": "upsert",
        "table.name.format":"'${sink_table}'"
    }'
echo ''
echo Postgres sink connector ${sink_connector} for topic ${sink_topic} created ✅
echo ''

source_topic_prefix=review-
source_connector=review-complete
source_table=status

echo Create table ${source_connector} for ${source_topic_prefix}-${source_table} created ...
docker exec -it postgres psql -U postgres -d postgres -c 'CREATE TABLE IF NOT EXISTS '${source_table}'(sequence_id SERIAL PRIMARY KEY, doc_id TEXT, is_relevant BOOLEAN);' 
echo Table ${source_connector} created ✅;
echo ''

echo Creating Posrgres source connector ${source_connector} for topic ${source_topic_prefix} ...;
curl -X PUT http://${connect_host}:${connect_port}/connectors/${source_connector}/config \
    -H "Content-Type: application/json" \
    -d '{
        "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url": "jdbc:postgresql://'${postgres_host}':'${postgres_port}'/",
        "connection.user": "'${postgres_user}'",
        "connection.password": "'${postgres_pass}'",
        "tasks.max": "1",
        "topic.prefix": "'${source_topic_prefix}'",
        "mode":"incrementing",
        "table.whitelist":"'${source_table}'",
        "incrementing.column.name":"sequence_id",
        "output.data.format":"AVRO"
    }'
echo ''
echo Postgres source connector ${source_connector} for topic ${source_topic_prefix}-${source_table} created ✅
echo ''

# https://phac.retool.com/apps/4a92e650-fc32-11ed-907b-87a421a42551/Review%20pending%20articles
# docker exec -it postgres psql -U postgres -d postgres -c 'UPDATE pending_review SET is_reviewed=FALSE;'
# docker exec -it postgres psql -U postgres -d postgres -c 'DELETE FROM status;'
