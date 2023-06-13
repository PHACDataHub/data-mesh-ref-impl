# !/bin/bash

./build_image.sh dedup_by_id workflow.yaml main conf/std-requirements.txt conf/avro
./build_image.sh language_detector workflow.yaml main conf/huggingface-requirements.txt conf/avro
./build_image.sh machine_translator workflow.yaml main conf/huggingface-requirements.txt conf/avro
./build_image.sh dedup_by_content workflow.yaml main conf/huggingface-requirements.txt conf/avro
./build_image.sh off_topic_filterer workflow.yaml main conf/huggingface-requirements.txt conf/avro
./build_image.sh topic_categorizer workflow.yaml main conf/stanza-requirements.txt conf/avro
./build_image.sh geo_locator workflow.yaml main conf/stanza-requirements.txt conf/avro
./build_image.sh summarizer workflow.yaml main conf/huggingface-requirements.txt conf/avro