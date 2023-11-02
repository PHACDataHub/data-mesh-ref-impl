#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/get_connector_info.sh <connector>";
    exit 1
fi

connector=$1

source .env

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

echo "About connector ${connector}..." 
echo "curl --silent -X GET http://${connect_host}:${connect_port}/connectors/${connector} | jq .[]"
curl --silent -X GET http://${connect_host}:${connect_port}/connectors/${connector} | jq .[]
echo