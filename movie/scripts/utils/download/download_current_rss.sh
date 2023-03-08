#!/bin/bash

folder=/data

echo 'Downloading data into for filepulse folder ...'
timestamp=$(date +%s%N)
curl --show-error --silent https://screenrant.com/feed/ -o ${folder}/screenrant-rss-${timestamp}.xml
echo ${folder}/screenrant-rss-${timestamp}.xml is downloaded. ✅
echo ''
