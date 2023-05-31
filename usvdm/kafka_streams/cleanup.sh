#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

./cleanup.sh

cd ${curr_dir}
