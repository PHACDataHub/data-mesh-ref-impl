#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/movie-rec/wait_for_connector.sh <connector>";
    exit 1
fi

connector=$1

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083

echo "Wait for connector ${connector} ..." 

error=$(curl -s XGET http://${connect_local_host}:${connect_port}/connectors/${connector} | jq '.error_code' )

while [ "$error" == "404" ]
do
    error=$(curl -s XGET http://${connect_local_host}:${connect_port}/connectors/${connector} | jq '.error_code' )
    sleep 1
done

echo ${connector} "connector ready ✅";
