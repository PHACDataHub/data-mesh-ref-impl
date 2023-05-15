#!/bin/bash

curr_dir=$(pwd)

for item in persons vaccines vaccination-events adverse-effects
do
    ./remove_topic.sh $item
done

cd ../kafka_cluster

./cleanup.sh

cd ${curr_dir}
