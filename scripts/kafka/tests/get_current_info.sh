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

echo "Listing all available plugins ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins |jq '.[].class'
echo ''

echo "Listing all connectors ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo "List all topics ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''
