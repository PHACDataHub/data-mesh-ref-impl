#!/bin/bash

set -e

python src/csv2avro.py governance/events ~/synthea/ca_spp/AB/csv/2023_10_19T18_15_33Z data
