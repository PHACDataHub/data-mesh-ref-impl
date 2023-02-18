# !/bin/bash

valid_images="question-answer, summarizer, text-classifier"

if [ $# -eq 0 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
    echo "Usage: ./scripts/nlp/build_image.sh <image_name>"
    echo "image_name is one of: "${valid_images}
    exit
fi

docker build -t $1 -f conf/nlp/$1/Dockerfile .