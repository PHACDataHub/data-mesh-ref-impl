#!/bin/bash

source .env

echo 'Creating constraints and indexes ...'
sudo cp analytics/neo4j/entity_constraints.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/entity_constraints.cql
echo 'Constraints and indexes are created ✅'
