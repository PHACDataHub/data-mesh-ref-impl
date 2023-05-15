#!/bin/bash

curr_dir=$(pwd)

sudo apt install -y jq wget

cd ../kafka_cluster

./setup.sh
./start.sh

cd ${curr_dir}

for item in persons vaccines vaccination-events adverse-effects
do
    ./create_topic.sh $item
    ./produce_messages.sh $item
done