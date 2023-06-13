# !/bin/bash

valid_images="dedup_by_id language_detector machine_translator dedup_by_content off_topic_filterer topic_categorizer geo_locator summarizer"

if [ $# -lt 5 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
    echo "Usage: ./build_image.sh <image_name> <yaml_file> <workflow_name> <python_requirements_file> <avro_directory>"
    echo "   where image_name is one of: ${valid_images}"
    echo "Example: ./build_image.sh dedup_by_id workflow.yaml main conf/std-requirements.txt conf/avro"
    exit
fi

# Assign arguments for Dockerfile
STEP_NAME=$1
WORKFLOW_FILE=$2
WORKFLOW_NAME=$3
PYTHON_REQUIREMENTS=$4
AVRO_DIR=$5

if [ $STEP_NAME != "dedup_by_id" ] && [ $STEP_NAME != "topic_categorizer" ] && [ $STEP_NAME != "geo_locator" ]; then
    # Temporary fix for 401 error
    docker pull nvcr.io/nvidia/pytorch:23.01-py3
    BASE_IMAGE=nvcr.io/nvidia/pytorch:23.01-py3
else
    BASE_IMAGE=python:3.11
fi

# Build the image
docker build -t $1:latest --build-arg STEP_NAME=$1 --build-arg WORKFLOW_FILE=$2 --build-arg WORKFLOW_NAME=$3 --build-arg PYTHON_REQUIREMENTS=$4 --build-arg AVRO_DIR=$5 --build-arg BASE_IMAGE=$BASE_IMAGE -f conf/docker/Dockerfile .
