#!/bin/bash

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

echo "All available plugins ...";
echo "curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins | jq '.[].class'"
curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins | jq '.[].class'
echo ''
