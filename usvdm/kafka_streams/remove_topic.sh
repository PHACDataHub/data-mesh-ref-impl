#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

source .env

topic=$1

data_file=${topic}.txt

./scripts/delete_subject.sh ${topic}-key

./scripts/delete_subject.sh ${topic}-value

./scripts/list_subjects.sh

./scripts/delete_topic.sh ${topic}

rm kafka-ce/schema-registry/data/$data_file

cd ${curr_dir}