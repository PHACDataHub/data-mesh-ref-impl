#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage ./scripts/download_faers_qdef.sh <year> <quarter>";
    echo "Example: ./scripts/download_faers_qdef.sh 2022 Q4";
    exit 1
fi

year=$1
quarter=$2

zip_file=faers_ascii_${year}${quarter}.zip
folder=data/faers/${year}${quarter}
url=https://fis.fda.gov/content/Exports/

echo Downloading ${url}${zip_file} ...
mkdir -p ${folder};
wget ${url}${zip_file} --output-document ${folder}/${zip_file}
unzip -o ${folder}/${zip_file} -d ${folder}
echo ${url}${zip_file} downloaded and extracted ✅
echo 
