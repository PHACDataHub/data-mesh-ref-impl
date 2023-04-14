#!/bin/bash

if [ $# -lt 2 ]; then
    echo "ERROR: Incorrect number of command line arguments ❌";
    echo ''
    echo 'Usage: ./scripts/utils/download/download_current_rss.sh <entity> <url> <folder>'
    echo './scripts/utils/download/download_current_rss.sh screenrant https://screenrant.com/feed/ kafka-ce/connect/data/filepulse/xml'
    echo ''
    exit 1
fi

entity=$1
url=$2

if [ -z "$3" ]; then
    folder=/data
else
    folder=$3
fi


echo Downloading rss feed for ${entity} from ${url} into folder ${folder} ...
timestamp=$(date +%s%N)
curl --show-error --silent ${url} -o ${folder}/${entity}-rss-${timestamp}.xml
echo ${folder}/${entity}-rss-${timestamp}.xml created. ✅
echo ''
