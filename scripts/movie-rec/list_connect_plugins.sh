#!/bin/bash

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083

echo "Listing all available plugins ...";
echo "curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins | jq '.[].class'"
curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins | jq '.[].class'
echo ''
