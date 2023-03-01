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
topic=${entity}-topic
connector=${entity}-filepulse-connector
subject=${topic}-value
consumer_group=${entity}-consumer-group

timeout_ms=5000
test_internal_ms_setup=1000

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
