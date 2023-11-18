#!/bin/bash

source .env

echo 'Creating constraints and indexes ...'
sudo cp analytics/v2_neo4j/v2_entity_constraints.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/v2_entity_constraints.cql
echo 'Constraints and indexes are created ✅'
