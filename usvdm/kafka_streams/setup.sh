#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

./setup.sh
./start.sh

cd ${curr_dir}
