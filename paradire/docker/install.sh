#!/bin/bash

# Check if Docker Engine is already installed
if [ -x "$(command -v docker)" ]; then
    echo "Docker already installed ❌"
    exit 1
fi

# Check if Docker Compose CLI Plugin version is given as argument
if [ -z "$1" ]; then
    COMPOSE_VERSION=v2.20.3
else
  COMPOSE_VERSION=$1
fi

### Set up the repository ###

# Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt-get update -y
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  gnupg-agent \
  software-properties-common \
  lsb-release -y

# Add Docker’s official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL -C - https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg

# Use the following command to set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### Install Docker Engine ###

# Default umask may be incorrectly configured, preventing detection of the repository public key file. Try granting read permission for the Docker public key file before updating the package index:
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Update the apt package index
sudo apt-get update -y

# Install Docker Engine and containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# Download and install the Compose CLI plugin
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

# Apply executable permissions to the binary
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

### Manage Docker as a non-root user ###

# Create the docker group
[ $(getent group docker) ] || sudo groupadd docker

# Add your user to the docker group.
sudo usermod -aG docker $USER

# Activate the changes to groups without logout (not recommended)
# newgrp docker

echo 'Logout and relogin ✅'
