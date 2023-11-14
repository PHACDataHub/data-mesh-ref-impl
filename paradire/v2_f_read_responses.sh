#!/bin/bash

source .env

timeout=10000

for item in {1..9}
do
    response_topic=fas_${item}
    
    consumer_group=${response_topic}

    echo "Consume up to ${response_messages} messages from ${response_topic} ..." 
    docker exec -it ${schema_registry_container} kafka-avro-console-consumer  \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --topic ${response_topic} --group ${consumer_group} --from-beginning --timeout-ms ${timeout}\
        --property schema.registry.url=http://${schema_registry_internal_host}:${schema_registry_port}
    echo ''
    echo Reset all consumer offsets of ${consumer_group} consumer group ...
    echo "docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
    "
    docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
        --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
        --group ${consumer_group} --reset-offsets --to-earliest --all-topics --execute;
    echo "Consumer offsets reset ✅";
    echo ''
done
