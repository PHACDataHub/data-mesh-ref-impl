#!/bin/bash

echo 'Creating constraints and indexes ...'
sudo cp conf/health_analytics_neo4j_constraints.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/health_analytics_neo4j_constraints.cql
echo 'Constraints and indexes are created ✅'
