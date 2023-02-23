#!/bin/bash

echo 'Downloading IMDb dataset ...'
for item in name.basics.tsv title.akas.tsv title.basics.tsv title.crew.tsv title.episode.tsv title.principals.tsv title.ratings.tsv
do
    curl --show-error https://datasets.imdbws.com/${item}.gz -O --output-dir ./
    gzip -d ${item}.gz
    sudo mv ${item} data/neo4j/import/.
done
echo 'IMDb dataset downloaded ✅'
