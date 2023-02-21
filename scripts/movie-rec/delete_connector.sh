#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/delete_connector.sh <connector>";
    exit 1
fi

connector=$1

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083

echo "Delete connector ..." 
echo "curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector} | jq .[]"
curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector} | jq .[]
echo ${connector} "connector deleted ✅";
