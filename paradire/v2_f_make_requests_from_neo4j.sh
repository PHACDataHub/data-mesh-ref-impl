#!/bin/bash

source .env

echo 'Creating federated analytics requests ...'
sudo cp analytics/v2_neo4j/v2_f_create_fed_requests.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/v2_f_create_fed_requests.cql
echo 'Federated analytics requests are created ✅'
