# !/bin/bash

valid_images="keyphrase_extractor keyphrase_extractor2 keyphrase_extractor3 keyphrase_extractor4 stanford_corenlp"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
    echo "Usage: ./build_image.sh <image_name> <step_name> <yaml_file> <workflow_name> <python_requirements_file> <avro_directory>"
    echo "   where image_name is one of: ${valid_images}"
    echo "Example: ./build_image.sh keyphrase_extractor keyphrase_extractor workflow.yaml main conf/keyphrase_extractor-requirements.txt conf/avro"
    exit
fi

PYTORCH_VERSION=23.06-py3
PYTHON_VERSION=3.11

# Assign arguments for Dockerfile
IMAGE_NAME=$1
STEP_NAME=$2
WORKFLOW_FILE=$3
WORKFLOW_NAME=$4
PYTHON_REQUIREMENTS=$5
AVRO_DIR=$6
TEST_ARGS=$7

if [ $IMAGE_NAME != "stanford_corenlp" ] && [ $IMAGE_NAME != "keyphrase_extractor" ] && [ $IMAGE_NAME != "keyphrase_extractor2" ] && [ $IMAGE_NAME != "keyphrase_extractor3" ] && [ $IMAGE_NAME != "keyphrase_extractor4" ]; then
    # Temporary fix for 401 error
    docker pull nvcr.io/nvidia/pytorch:${PYTORCH_VERSION}
    BASE_IMAGE=nvcr.io/nvidia/pytorch:${PYTORCH_VERSION}
else
    BASE_IMAGE=python:${PYTHON_VERSION}
fi

# Build the image
if [ $IMAGE_NAME != "stanford_corenlp" ] ; then
    if [ $# -lt 6 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
        echo "Usage: ./build_image.sh <image_name> <yaml_file> <workflow_name> <python_requirements_file> <avro_directory>"
        echo "   where image_name is one of: ${valid_images}"
        echo "Example: ./build_image.sh dedup_by_id workflow.yaml main conf/std-requirements.txt conf/avro"
        exit
    fi
    docker build --network host -t $IMAGE_NAME:latest --build-arg STEP_NAME=$STEP_NAME --build-arg WORKFLOW_FILE=$WORKFLOW_FILE --build-arg WORKFLOW_NAME=$WORKFLOW_NAME \
    --build-arg PYTHON_REQUIREMENTS=$PYTHON_REQUIREMENTS --build-arg AVRO_DIR=$AVRO_DIR --build-arg TEST_ARGS=$TEST_ARGS  --build-arg BASE_IMAGE=$BASE_IMAGE \
    -f conf/docker/pipeline/Dockerfile .
else
    docker build --network host -t $IMAGE_NAME:latest -f conf/docker/stanford_corenlp/Dockerfile .
fi
