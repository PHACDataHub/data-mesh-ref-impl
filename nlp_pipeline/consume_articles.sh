#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

rest_proxy_host=${REST_PROXY_HOST}
rest_proxy_port=${REST_PROXY_PORT}

topic=summarized-articles
consumer_group=rest_consumer_group
consumer_instance=rest_consumer_instance

echo Create consumer group and consumer instance ...
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
    --data '{"name": "'${consumer_instance}'", "format": "avro", "auto.offset.reset": "earliest" }' \
    http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_group}
echo ''
echo ''

echo Subscribe to the topic ...
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["summarized-articles"]}' \
    http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_group}/instances/${consumer_instance}/subscription
echo ''

echo Consume messages ...

# Note that you must issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432)
for i in 1 2
do
    return=$(curl --silent -X GET -H "Accept: application/vnd.kafka.avro.v2+json" \
        http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_group}/instances/${consumer_instance}/records)
    if [ -z "$return" ]; then
        echo Wait for 5 seconds ...
        sleep 5
    else
        echo $return | jq '.[]'
    fi
done

echo Delete consumer instance ${consumer_instance} ...
curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" \
    http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_group}/instances/${consumer_instance}
echo ''

echo Delete consumer group ${consumer_group} ...;
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --delete-offsets --group ${consumer_group} --execute;
echo ''
