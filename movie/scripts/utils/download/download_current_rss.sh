#!/bin/bash

folder=data/rss
mkdir -p ${folder};

echo 'Downloading data into for filepulse folder ...'
timestamp=$(($(date +%s%N)/1000000))
curl --show-error --silent https://screenrant.com/feed/ -o ${folder}/screenrant-rss-${timestamp}.xml
echo ${folder}/screenrant-rss-${timestamp}.xml is downloaded. ✅
echo ''
