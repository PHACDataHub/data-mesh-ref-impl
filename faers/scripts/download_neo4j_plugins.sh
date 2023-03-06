#!/bin/bash

source .env

for item in $@
do
    echo Downloading plugins for ${item} ...
    wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${NEO4J_VERSION}/apoc-${NEO4J_VERSION}-extended.jar 
    sudo mv apoc-${NEO4J_VERSION}-extended.jar ${item}/plugins/.
    echo Plugins for ${item} downloaded ✅
    echo 
done
