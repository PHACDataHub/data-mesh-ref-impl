#!/bin/bash

# Verify that:
# - the Docker Engine installation is successful by running the hello-world image
# - you can run docker commands without sudo.
docker run hello-world

# If permission settings for the ~/.docker/ directory are incorrect, then:
# sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
# sudo chmod g+rwx "$HOME/.docker" -R

# Test docker compose
docker compose version

echo 'Docker is ready ✅'