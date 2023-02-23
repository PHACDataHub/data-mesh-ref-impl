# !/bin/bash

valid_images="question-answer, summarizer, text-classifier, sentiment-analyzer, named-entity-recognizer, preprocessor"

if [ $# -eq 0 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
    echo "Usage: ./scripts/nlp/build_image.sh <image_name> <ini_path>"
    echo "image_name is one of: "${valid_images}
    exit
fi

ini_path=$2
if [ -z "$ini_path" ]; then
    ini_path=conf/movie-rec/ini
fi

avro_path=$3
if [ -z "$avro_path" ]; then
    avro_path=conf/movie-rec/avro
fi

docker build -t $1:latest --build-arg INI_FILE=$ini_path/$1.ini --build-arg AVRO_PATH=${avro_path} -f conf/nlp/docker/nlp_task.Dockerfile .