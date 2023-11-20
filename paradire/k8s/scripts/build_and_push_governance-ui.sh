#!/bin/bash
set -e

# Constants
LOCATION="northamerica-northeast1-docker.pkg.dev"
PROJECT="phx-01he5rx4wsv"
REGISTRY="paradire"

DOCKER_IMG_NAME="governance-ui"
TAG="latest"

# Setup docker authentication
sudo docker login -u oauth2accesstoken -p "$(gcloud auth print-access-token)" https://$LOCATION

IMAGE="$LOCATION/$PROJECT/$REGISTRY/$DOCKER_IMG_NAME:$TAG"

# Build and push Docker image
sudo docker build . -f ./governance/governance-ui/Dockerfile -t "$IMAGE"
sudo docker push $IMAGE