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

if [ "$1" == "preprocessor" ]; then
    avro_files=$3
    if [ -z "$avro_files" ]; then
        avro_files=conf/movie-rec/avro/screenrant-rss-value.avsc
    fi
    docker build -t $1:latest --build-arg INI_FILE=$ini_path/$1.ini --build-arg AVRO_FILES="${avro_files}" -f conf/nlp/docker/preprocessor.Dockerfile .
else
    docker build -t $1:latest --build-arg INI_FILE=$ini_path/$1.ini -f conf/nlp/docker/nlp_task.Dockerfile .
fi