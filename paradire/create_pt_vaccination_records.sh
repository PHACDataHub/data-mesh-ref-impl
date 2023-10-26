#!/bin/bash

set -e

source .env

echo 'Generating a stream of vaccination records ...'
sudo cp analytics/neo4j/streams_generator.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/streams_generator.cql
echo 'A stream of vaccination records created ✅'
