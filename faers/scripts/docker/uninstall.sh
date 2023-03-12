#!/bin/bash

# Uninstall the Docker Engine, CLI, containerd, and Docker Compose packages
sudo apt-get purge docker-ce docker-ce-cli containerd.io -y 

# Images, containers, volumes, or custom configuration files on your host aren’t automatically removed. To delete all images, containers, and volumes
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
rm -rf $DOCKER_CONFIG/cli-plugins

echo 'Docker is removed ✅'