#!/bin/bash

for item in vaccine-standards vaccine-lot-info persons-BC persons-ON persons-QC vaccination-events-BC vaccination-events-ON vaccination-events-QC adverse-effects-BC adverse-effects-ON adverse-effects-QC
do
    ./produce_messages.sh $item
done

./create_stream_processing.sh

consumer_group=console-consumer

curr_dir=$(pwd)
cd ../kafka_cluster
./scripts/reset_consumer_all_offsets.sh ${consumer_group}
cd ${curr_dir}

./consume_messages.sh enriched-vaccination-records-BC 4 ${consumer_group}
./consume_messages.sh enriched-vaccination-records-ON 5 ${consumer_group}
./consume_messages.sh enriched-vaccination-records-QC 4 ${consumer_group}

./consume_messages.sh enriched-adverse-effects-report-BC 2 ${consumer_group}
./consume_messages.sh enriched-adverse-effects-report-ON 1 ${consumer_group}
./consume_messages.sh enriched-adverse-effects-report-QC 1 ${consumer_group}

