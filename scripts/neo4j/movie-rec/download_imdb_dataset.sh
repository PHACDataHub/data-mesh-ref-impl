#!/bin/bash

echo 'Downloading IMDb dataset ...'
for item in name.basics.tsv title.akas.tsv title.basics.tsv title.crew.tsv title.episode.tsv title.principals.tsv title.ratings.tsv
do
    # curl --show-error --silent https://datasets.imdbws.com/${item}.gz -O --output-dir ./
    # gzip -df ${item}.gz
    # sed -i 's/"/\\"/g' ${item}
    sudo cp ${item} data/neo4j/import/.
done
echo 'IMDb dataset downloaded ✅'
