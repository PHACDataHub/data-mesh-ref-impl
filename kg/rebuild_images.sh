# !/bin/bash

./build_image.sh keyphrase_extractor keyphrase_extractor workflow.yaml main conf/python/keyphrase_extractor-requirements.txt conf/avro
# ./build_image.sh keyphrase_extractor2 keyphrase_extractor workflow.yaml main conf/python/keyphrase_extractor-requirements.txt conf/avro
# ./build_image.sh keyphrase_extractor3 keyphrase_extractor workflow.yaml main conf/python/keyphrase_extractor-requirements.txt conf/avro
# ./build_image.sh keyphrase_extractor4 keyphrase_extractor workflow.yaml main conf/python/keyphrase_extractor-requirements.txt conf/avro
# ./build_image.sh stanford_corenlp 

echo Images built ✅