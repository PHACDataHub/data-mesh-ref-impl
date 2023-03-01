#!/bin/bash

echo 'Copying IMDb dataset ...'
sudo cp *.tsv data/neo4j/import/.
sudo cp conf/movie-rec/neo4j/*.header.tsv data/neo4j/import/.
echo 'IMDb dataset copied ✅'

echo 'Stop the current default database (neo4j)...'
sudo cp conf/movie-rec/neo4j/neo4j_stop_database.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_stop_database.cql
docker exec -it neo4j bash -c 'rm -rf /data/transactions/neo4j'
echo 'The current default database (neo4j) is stopped ✅'

echo 'Perform low-level data import ...'
docker exec -it neo4j bash -c 'bin/neo4j-admin database import full --delimiter=TAB --nodes Name=/import/name.basics.header.tsv,/import/name.basics.tsv --nodes Title=/import/title.basics.header.tsv,/import/title.basics.tsv --nodes Crew=/import/title.crew.header.tsv,/import/title.crew.tsv --nodes Rating=/import/title.ratings.header.tsv,/import/title.ratings.tsv --relationships CREW_IN=/import/title.principals.header.tsv,/import/title.principals.tsv --relationships PART_OF=/import/title.episode.header.tsv,/import/title.episode.tsv --skip-bad-relationships=true neo4j'
echo 'Low-level data import completed ✅'

echo 'Database is being restarted ...'
./scripts/neo4j/stop.sh 
./scripts/neo4j/start_again.sh 
echo 'Database is restarted ✅'

echo 'Restart the current default database (neo4j)...'
sudo cp conf/movie-rec/neo4j/neo4j_start_database.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 -d system --file /import/neo4j_start_database.cql
echo 'The current default database (neo4j) is restarted ✅'

echo 'Creating constraints and indexes ...'
sudo cp conf/movie-rec/neo4j/neo4j_constraints.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_constraints.cql
echo 'Constraints and indexes are created ✅'

echo 'Applying constraints and indexes ...'
sudo cp conf/movie-rec/neo4j/neo4j_import.cql data/neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2022 --file /import/neo4j_import.cql
echo 'Constraints and indexes are applied ✅'
