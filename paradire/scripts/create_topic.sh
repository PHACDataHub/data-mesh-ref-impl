#!/bin/bash

# Check if a topic name is provided
if [ -z "$1" ]; then
    echo "Usage ./scripts/create_topic.sh <topic>";
    exit 1
fi

topic=$1

# Load environment variables
source .env

# Kafka broker details
broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}
replication_factor=${REPLICATION_FACTOR}
partitions=${PARTITIONS}

# Check if the topic already exists
echo "Checking if topic ${topic} already exists..."
existing_topics=$(docker exec ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --list)

if echo "$existing_topics" | grep -w "^${topic}$"; then
    echo "Topic ${topic} already exists."
else
    # Create the topic if it does not exist
    echo "Creating topic ${topic}..."
    set +e  # Disable exit on error temporarily
    docker exec ${broker_container_name} /bin/kafka-topics \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --create --topic ${topic} --partitions ${partitions} --replication-factor ${replication_factor}
    create_status=$?
    set -e  # Re-enable exit on error

    # Check if the topic creation was successful
    if [ "$create_status" = "0" ]; then
        echo "${topic} created ✅"
    else
        echo "Failed to create topic ${topic}"
        exit 1
    fi
fi

echo ''
