#!/bin/bash

source .env

echo 'Creating federated analytics requests ...'
sudo cp analytics/neo4j/f_create_fed_requests.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/f_create_fed_requests.cql
echo 'Federated analytics requests are created ✅'
