#!/bin/bash

if [[ $(uname -s) == 'Darwin' ]]; then
    platform=mac
else
    platform=linux
fi

folder=data/imdb
mkdir -p ${folder};

for item in name.basics title.basics title.crew title.episode title.principals title.ratings 
do
    if [ -f ${folder}/${item}.tsv ]; then
        echo ${folder}/${item}.tsv already downloaded.
        continue
    fi
    file_name=${item}.tsv.gz
    url=https://datasets.imdbws.com/${file_name}
    echo Downloading ${url} ...
    wget ${url} --output-document ${file_name}
    gzip -d ${file_name}
    if [[ "$platform" == 'linux' ]]; then
        sed -i 's/"/\\"/g' ${item}.tsv
    else
        sed -e 's/"/\\"/g' ${item}.tsv > ${item}.tsv.1
        mv ${item}.tsv.1 ${item}.tsv
    fi
    mv ${item}.tsv ${folder}/.
    ls -la ${folder}/${item}.tsv
done
