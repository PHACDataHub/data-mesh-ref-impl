#!/bin/bash

echo 'Creating constraints and indexes ...'
sudo cp conf/movie-rec/neo4j/neo4j_constraints.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_constraints.cql
echo 'Constraints and indexes are created ✅'
