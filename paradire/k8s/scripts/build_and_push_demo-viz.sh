#!/bin/bash
set -e

# Constants
LOCATION="northamerica-northeast1-docker.pkg.dev"
PROJECT="phx-01he5rx4wsv"
REGISTRY="paradire"

DOCKER_IMG_NAME="demo-viz"
DOCKER_WS_IMG_NAME="demo-viz-wss"
TAG="latest"

# Setup docker authentication
sudo docker login -u oauth2accesstoken -p "$(gcloud auth print-access-token)" https://$LOCATION

IMAGE="$LOCATION/$PROJECT/$REGISTRY/$DOCKER_IMG_NAME:$TAG"
IMAGE_WS="$LOCATION/$PROJECT/$REGISTRY/$DOCKER_WS_IMG_NAME:$TAG"

# Build and push Docker image
sudo docker build . -f ./analytics/demo-viz/Dockerfile -t "$IMAGE"
sudo docker push $IMAGE

# Build and push WSS Docker image
sudo docker build . -f ./analytics/demo-viz/Dockerfile.wsserver -t "$IMAGE_WS"
sudo docker push $IMAGE_WS
