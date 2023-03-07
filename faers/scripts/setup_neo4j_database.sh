#!/bin/bash

source .env

echo 'Creating constraints and indexes ...'
sudo cp conf/neo4j/constraints.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /var/lib/neo4j/import/constraints.cql
echo 'Constraints and indexes are created ✅'
