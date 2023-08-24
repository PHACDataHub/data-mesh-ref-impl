#!/bin/bash

source .env

echo 'Creating constraints, indexes, and import data ...'
sudo cp conf/cql/neo4j_import.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/neo4j_import.cql
echo 'Constraints and indexes are created. Disease ontologies are imported ✅'
