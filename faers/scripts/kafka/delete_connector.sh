#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/kafka/delete_connector.sh <connector>";
    exit 1
fi

connector=$1

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

echo "Delete connector ..." 
echo "curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector} | jq .[]"
curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector} | jq .[]
echo ${connector} "connector deleted ✅";
