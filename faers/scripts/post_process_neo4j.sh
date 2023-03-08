#!/bin/bash

source .env

echo 'Run post processing ...'
sudo cp conf/neo4j/post_processing.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/post_processing.cql
echo 'Post processing complete ✅'
