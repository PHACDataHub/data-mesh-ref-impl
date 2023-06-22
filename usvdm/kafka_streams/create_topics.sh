#!/bin/bash

for item in vaccine-standards vaccine-lot-info persons-BC persons-ON persons-QC vaccination-events-BC vaccination-events-ON vaccination-events-QC adverse-effects-BC adverse-effects-ON adverse-effects-QC
do
    ./produce_messages.sh $item
done
