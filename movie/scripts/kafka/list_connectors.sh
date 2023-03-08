#!/bin/bash

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

echo "All current connectors ...";
echo "curl -s -XGET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'"
curl -s -XGET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''
