#!/bin/bash

./scripts/neo4j/movie-rec/download_imdb_dataset.sh
sudo cp conf/movie-rec/neo4j/neo4j_import.cql data/neo4j/import/.
echo 'Data is being imported ...'
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_import.cql
