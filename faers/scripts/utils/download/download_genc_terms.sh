#!/bin/bash

entity=("genc" "https://evs.nci.nih.gov/ftp1/GENC/" "NCIt-GENC_Terminology.txt")

if [ -f data/${entity[0]}/${entity[2]} ]; then
    echo data/${entity[0]}/${entity[2]} already downloaded.
    exit 0
fi

echo Downloading ${entity[1]}${entity[2]} ...
mkdir -p data/${entity[0]};
wget ${entity[1]}${entity[2]} --output-document data/${entity[0]}/${entity[2]}
file_name=data/${entity[0]}/${entity[2]}
header=$(head -n 1 $file_name | sed 's/ /_/g' |  tr '[:upper:]' '[:lower:]' | sed 's/_(fda_standard)//g')
sed -i "1s/.*/$header/" $file_name
echo ${entity[1]}/${entity[2]} downloaded ✅

echo 
