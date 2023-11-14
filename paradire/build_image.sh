# !/bin/bash

valid_images="acg_f2pt acg_pt2f"

if [ $# -lt 6 ] || [ -z "$(echo ${valid_images} | grep $1)" ]; then
    echo "Usage: ./build_image.sh <image_name> <step_name> <yaml_file> <workflow_name> <python_requirements_file> <avro_directory> <test_argument>"
    echo "   where image_name is one of: ${valid_images}"
    echo "Example: ./build_image.sh acg_f2pt acg_f2pt v2_workflow.yaml main analytics/dockerized/acg_worker-requirements.txt analytics/event /data"
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

if [ $IMAGE_NAME != "acg_f2pt" ] && [ $IMAGE_NAME != "acg_pt2f" ]; then
    # Temporary fix for 401 error
    docker pull nvcr.io/nvidia/pytorch:${PYTORCH_VERSION}
    BASE_IMAGE=nvcr.io/nvidia/pytorch:${PYTORCH_VERSION}
else
    BASE_IMAGE=python:${PYTHON_VERSION}
fi

docker build --network host -t $IMAGE_NAME:latest --build-arg STEP_NAME=$STEP_NAME --build-arg WORKFLOW_FILE=$WORKFLOW_FILE --build-arg WORKFLOW_NAME=$WORKFLOW_NAME \
--build-arg PYTHON_REQUIREMENTS=$PYTHON_REQUIREMENTS --build-arg AVRO_DIR=$AVRO_DIR --build-arg TEST_ARGS=$TEST_ARGS  --build-arg BASE_IMAGE=$BASE_IMAGE \
-f analytics/dockerized/Dockerfile .
