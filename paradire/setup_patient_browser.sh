#!/bin/bash
set -e

# Constants
DOCKER_IMG_NAME="patient-browser"
DOCKER_CONTAINER_NAME="patient-browser"
DOCKER_PORT=9090

# Navigate to the "patient-browser" directory
curr_dir=$(pwd)
cd $curr_dir/patient_browser_patch

# Create a Dockerfile
cat <<EOL > Dockerfile
# First stage: Clone and build the project
FROM node:latest AS build

# Install git, TypeScript, and other dependencies
RUN apt-get update && apt-get install -y git
RUN npm install -g typescript

# Set the working directory
WORKDIR /app

# Clone the patient-browser repository
RUN git clone https://github.com/smart-on-fhir/patient-browser.git .

# Copy patches from host to container
COPY . .

# Install dependencies and build project
RUN npm install colors request commander@2.15.1
RUN npm ci
RUN NODE_ENV=production npm run build

# Configure the browser
RUN mv default.json5 ./dist/config/

# Setup the nginx server
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
EOL

# Build and run Docker image
sudo docker build . -t "$DOCKER_IMG_NAME"
sudo docker run -d --restart always --name "$DOCKER_CONTAINER_NAME" -p "$DOCKER_PORT":80 "$DOCKER_IMG_NAME"

echo "Patient browser started on http://localhost:$DOCKER_PORT"

cd "$curr_dir"
