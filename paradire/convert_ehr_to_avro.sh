#!/bin/bash

set -e

if [ -z "$1" ]; then
    if [ -d "data" ]; then
        data_dir=data
    else
        echo "Usage: ./convert_ehr_to_avro.sh <csv_dir> <avro_dir>"
        echo "Example: ./convert_ehr_to_avro.sh ~/synthea/ca_spp/AB/csv/2023_10_19T18_15_33Z data"
        exit 1
    fi
else
    data_dir=$1
fi


python src/csv2avro.py governance/events $1 data
