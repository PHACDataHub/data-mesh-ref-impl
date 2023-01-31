#!/bin/bash

echo 'Importing data ...'
sudo cp conf/health-analytics/neo4j_import.cql data/neo4j/import/.
sudo cp data/health-analytics/csv/*.csv data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_import.cql
echo 'Data is imported ✅'
