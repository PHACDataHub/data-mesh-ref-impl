#!/bin/bash

source .env

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

echo "All current connectors ...";
echo "curl -s -XGET http://${connect_host}:${connect_port}/connectors | jq '.[]'"
curl -s -XGET http://${connect_host}:${connect_port}/connectors | jq '.[]'
echo ''
