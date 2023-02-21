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

# Download the current RSS feed from https://screenrant.com/feed/
# In production it is recommended to run a cronjob, note that the feed is updated frequently
# We don't worry about duplication, since the messages are fed into Kafka and it will eliminate duplicates - depending on our choice for unique constraints
./scripts/movie-rec/download_current_rss.sh

# List the current Connect plugins
# What we need is the "io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector"
./scripts/movie-rec/list_connect_plugins.sh

# List the current connector instances
# It could show an earlier version of the "filepulse-screenrant" connector, but don't worry, it will be updated
./scripts/movie-rec/list_connectors.sh

# List the current topics
# It could show that the topic "topic-screenrant" exists, but that will have no effect
./scripts/movie-rec/list_topics.sh

# List the current subject in the "schema registry" of the Kafka cluster
# It could show that the subject "topic-screenrant-value" exists, this script will update it with a new version
./scripts/movie-rec/list_subjects.sh

# Create the FilePulse connector with the configuration shown above to read XML messages
./scripts/movie-rec/create_filepulse_connector.sh ${topic} ${connector} ${test_internal_ms_setup}

# Wait until the connector instance becomes available
./scripts/movie-rec/wait_for_connector.sh ${connector}

# Wait until the schema registry subject becomes available
./scripts/movie-rec/wait_for_subject.sh ${subject}

# Wait until the topic becomes available
./scripts/movie-rec/wait_for_topic.sh ${topic}

# The FilePulse source connector instance will 
# - automatically kick-in, 
# - reading messages, 
# - process them according to the "filters" instructions
# - convert them from XML into AVRO messages according to the schema (now) stored in the schema registry
# - produce these messages into the topic

# Test consuming messages with in a number of seconds
# The consumer_group variable is used to define a consumer group,
# that will be used to reset the consumer offsets if messages need to be reread
./scripts/movie-rec/consume_messages.sh ${topic} ${timeout_ms} ${consumer_group}
echo ''

# Here messages are reread and reprocessed
echo Reset consumer offset and consume again ✅
./scripts/movie-rec/consume_messages.sh ${topic} ${timeout_ms} ${consumer_group}

# Subject, topic, and connector instance are deleted to cleanup the cluster
./scripts/movie-rec/delete_subject.sh ${subject}
./scripts/movie-rec/delete_topic.sh ${topic}
./scripts/movie-rec/delete_connector.sh ${connector}

# Downloaded RSS files are removed
./scripts/movie-rec/remove_all_downloaded_rss.sh