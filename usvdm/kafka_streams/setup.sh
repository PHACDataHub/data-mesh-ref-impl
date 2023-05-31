#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

./setup.sh
./start.sh

cd ${curr_dir}

for item in vaccines persons-BC persons-ON persons-QC vaccination-events-BC vaccination-events-ON vaccination-events-QC adverse-effects-BC adverse-effects-ON adverse-effects-QC
do
    ./create_topic.sh $item
    ./produce_messages.sh $item
done