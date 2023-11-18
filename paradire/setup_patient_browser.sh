#!/bin/bash
set -e

# Constants
DOCKER_IMG_NAME="patient-browser"
DOCKER_CONTAINER_NAME="patient-browser"
DOCKER_PORT=9090

# Navigate to the "patient-browser" directory
curr_dir=$(pwd)
cd $curr_dir/patient_browser_patch

# Build and run Docker image
sudo docker build . -t "$DOCKER_IMG_NAME"
sudo docker run -d --restart always --name "$DOCKER_CONTAINER_NAME" -p "$DOCKER_PORT":80 "$DOCKER_IMG_NAME"

echo "Patient browser started on http://localhost:$DOCKER_PORT"

cd "$curr_dir"