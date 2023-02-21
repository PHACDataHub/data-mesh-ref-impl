#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/wait_for_topic.sh <topic>";
    exit 1
fi

topic=$1

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083

echo "Wait for topic ${topic} to be ready..." 

error=

while [ -z "$error" ]
do
    error=$(docker exec -it broker /bin/kafka-topics --bootstrap-server broker:29092 --describe --topic ${topic})
    sleep 1
done

echo Topic ${topic} with ${replicas} replications ready ✅;
