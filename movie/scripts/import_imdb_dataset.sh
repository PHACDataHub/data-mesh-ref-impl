#!/bin/bash

echo 'Copying IMDb dataset ...'
if [ -f neo4j/import/name.basics.tsv ]; then
    echo 'IMDb dataset already copied ✅'
else
    sudo cp data/imdb/*.tsv neo4j/import/.
    sudo cp conf/tsv/*.header.tsv neo4j/import/.
    echo 'IMDb dataset copied ✅'
fi

echo 'Stop the current default database (neo4j) ...'
docker exec -it neo4j bin/neo4j-admin server stop
echo 'Removing the current default database (neo4j) ...'
docker exec -it neo4j bash -c 'rm -rf /data/transactions/neo4j'
echo 'The current default database (neo4j) is stopped ✅'

echo 'Perform low-level data import ...'
docker exec -it neo4j bash -c 'bin/neo4j-admin database import full --delimiter=TAB --nodes Person=/import/name.basics.header.tsv,/import/name.basics.tsv --nodes Title=/import/title.basics.header.tsv,/import/title.basics.tsv --nodes Crew=/import/title.crew.header.tsv,/import/title.crew.tsv --nodes Rating=/import/title.ratings.header.tsv,/import/title.ratings.tsv --relationships CREW_IN=/import/title.principals.header.tsv,/import/title.principals.tsv --relationships PART_OF=/import/title.episode.header.tsv,/import/title.episode.tsv --skip-bad-relationships=true neo4j'
echo 'Low-level data import completed ✅'

echo 'Restart the current default database (neo4j)...'
docker exec -it neo4j bin/neo4j-admin server stop
docker exec -it neo4j bin/neo4j-admin server start
./scripts/utils/waits/wait_for_it.sh neo4j 60
echo 'The current default database (neo4j) is restarted ✅'

echo 'Creating constraints and indexes ...'
sudo cp conf/cql/neo4j_constraints.cql neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2023 --file /import/neo4j_constraints.cql
echo 'Constraints and indexes are created ✅'

echo 'Applying constraints and indexes ...'
sudo cp conf/cql/neo4j_import.cql neo4j/import/.
docker exec -u neo4j --interactive --tty  neo4j cypher-shell -u neo4j -p phac2023 --file /import/neo4j_import.cql
echo 'Constraints and indexes are applied ✅'
