#!/bin/bash

set -e

# if [ -d "~/3.10" ]; then
#     sudo apt install python3-venv -y
#     python3 -m venv ~/3.10
#     source ~/3.10/bin/activate
# fi

if [ -z "$1" ]; then
    echo "Usage: ./convert_ehr_to_avro.sh <schema_folder> <csv_folder> <symptoms_folder> <avro_folder>"
    echo "Example: ./convert_ehr_to_avro.sh governance/events ~/synthea/bc_spp/BC/csv/2023_11_08T15_35_59Z ~/synthea/bc_spp/BC/symptoms/csv/2023_11_08T15_36_00Z data"
    exit 1
fi

python src/csv2avro.py $@