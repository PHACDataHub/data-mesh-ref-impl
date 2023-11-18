#!/bin/bash

source .env

for item in $@
do
    echo Downloading plugins for ${item} ...
    echo 

    if [ -f ${item}/plugins/apoc-${NEO4J_APOC_VERSION}-core.jar ]; then
        echo ${item}/plugins/apoc-${NEO4J_APOC_VERSION}-core.jar already downloaded.
        continue
    fi
    wget https://github.com/neo4j/apoc/releases/download/${NEO4J_APOC_VERSION}/apoc-${NEO4J_APOC_VERSION}-core.jar 
    sudo mv apoc-${NEO4J_APOC_VERSION}-core.jar ${item}/plugins/.
    echo 
    
    if [ -f ${item}/plugins/apoc-${NEO4J_APOC_EXTENDED_VERSION}-extended.jar ]; then
        echo ${item}/plugins/apoc-${NEO4J_APOC_EXTENDED_VERSION}-extended.jar already downloaded.
        continue
    fi
    wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${NEO4J_APOC_EXTENDED_VERSION}/apoc-${NEO4J_APOC_EXTENDED_VERSION}-extended.jar 
    sudo mv apoc-${NEO4J_APOC_EXTENDED_VERSION}-extended.jar ${item}/plugins/.
    echo 

   echo Downloading plugins for ${item} ...
    if [ -f ${item}/plugins/neo4j-graph-data-science-${NEO4J_GDS_VERSION}.jar ]; then
        echo ${item}/plugins/neo4j-graph-data-science-${NEO4J_GDS_VERSION}.jar already downloaded.
        continue
    fi
    wget https://graphdatascience.ninja/neo4j-graph-data-science-${NEO4J_GDS_VERSION}.zip
    unzip neo4j-graph-data-science-${NEO4J_GDS_VERSION}.zip
    sudo mv neo4j-graph-data-science-${NEO4J_GDS_VERSION}.jar ${item}/plugins/.
    rm neo4j-graph-data-science-${NEO4J_GDS_VERSION}.zip
    echo 

    echo Plugins for ${item} downloaded ✅
    echo 
done

