#!/bin/bash

echo 'Importing data ...'
sudo cp conf/health_analytics_neo4j_import.cql data/neo4j/import/.
sudo cp data/csv/*.csv data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/health_analytics_neo4j_import.cql
echo 'Data is imported ✅'
