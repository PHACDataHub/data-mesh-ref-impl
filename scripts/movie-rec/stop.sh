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

entity=screenrant
topic=topic-${entity}
connector=filepulse-${entity}
subject=${topic}-value
consumer_group=${entity}-consumer

timeout_ms=5000
test_internal_ms_setup=1000

# Subject, topic, and connector instance are deleted to cleanup the cluster
./scripts/movie-rec/delete_subject.sh ${subject}
./scripts/movie-rec/delete_topic.sh ${topic}
./scripts/movie-rec/delete_connector.sh ${connector}

# Downloaded RSS files are removed
./scripts/movie-rec/remove_all_downloaded_rss.sh