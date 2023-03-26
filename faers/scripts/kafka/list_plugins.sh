#!/bin/bash

source .env

connect_container=connect
connect_internal_host=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

echo "All available plugins ...";
echo "curl -s -XGET http://${connect_host}:${connect_port}/connector-plugins | jq '.[].class'"
curl -s -XGET http://${connect_host}:${connect_port}/connector-plugins | jq '.[].class'
echo ''
