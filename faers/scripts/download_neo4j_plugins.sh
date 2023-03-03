#!/bin/bash

source .env

echo Downloading plugins for Neo4j ...
wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${NEO4J_VERSION}/apoc-${NEO4J_VERSION}-extended.jar 
mv apoc-${NEO4J_VERSION}-extended.jar neo4j/plugins/.
echo Plugins for Neo4j downloaded ✅
echo 
