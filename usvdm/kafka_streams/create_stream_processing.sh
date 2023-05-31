#!/bin/bash

curr_dir=$(pwd)

cd ../kafka_cluster

echo Copy in-stream processing instructions for ksqldb-cli ...
cp ${curr_dir}/conf/stream_processing.sql kafka-ce/ksqldb-cli/scripts/.
echo ''

echo Execute in-stream processing instructions for ksqldb-cli ...
docker exec -it ksqldb-cli bash -c 'cat /data/scripts/stream_processing.sql <(echo -e '\nEXIT')| ksql http://ksqldb-server:8088'
echo ''

cd ${curr_dir}