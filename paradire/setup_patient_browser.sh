#!/bin/bash
set -e

# Constants
DOCKER_IMG_NAME="patient-browser"
DOCKER_CONTAINER_NAME="patient-browser"
DOCKER_PORT=9090

# Note: Ensure FHIR server is running on localhost:8080 prior to running this script.
curr_dir=$(pwd)

# Check for "patient-browser" directory and clone if missing
if [ ! -d "$HOME/patient-browser" ]; then
    git clone https://github.com/smart-on-fhir/patient-browser.git "$HOME/patient-browser"
fi

cp "$curr_dir/patient_browser_patch/"* "$HOME/patient-browser"

# Navigate to the "patient-browser" directory
cd "$HOME/patient-browser"

# Create a Dockerfile
cat <<EOL > Dockerfile
FROM node:latest AS build

# Install TypeScript
RUN npm install -g typescript

# Set the working directory
WORKDIR /app

# Copy the local patient-browser directory to the container
COPY . .

# Install dependencies and build project
RUN npm install colors request commander@2.15.1
RUN npm ci
RUN NODE_ENV=production npm run build

# Configure the browser
RUN mv default.json5 ./dist/config/

# Disable the broken FHIR viewer
RUN sed -i 's/enabled: true/enabled: false/g' ./dist/config/default.json5

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
EOL

# Build and run Docker image
sudo docker build . -t "$DOCKER_IMG_NAME"
sudo docker run -d --restart always --name "$DOCKER_CONTAINER_NAME" -p "$DOCKER_PORT":80 "$DOCKER_IMG_NAME"

echo "Patient browser started on http://localhost:$DOCKER_PORT"

cd "$curr_dir"
