#!/bin/bash

echo 'Downloading data into for filepulse folder ...'
timestamp=$(($(date +%s%N)/1000000))
curl --show-error --silent https://screenrant.com/feed/ -o kafka-ce/connect/data/filepulse/xml/screenrant-rss-${timestamp}.xml
echo kafka-ce/connect/data/filepulse/xmlscreenrant-rss-${timestamp}.xml 'is downloaded. ✅'
echo ''
