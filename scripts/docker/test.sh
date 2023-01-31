#!/bin/bash

# Verify that:
# - the Docker Engine installation is successful by running the hello-world image
# - you can run docker commands without sudo.
docker run hello-world

# Permission settings for the ~/.docker/ directory are incorrect
# sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
# sudo chmod g+rwx "$HOME/.docker" -R

# Test docker compose
docker compose version

echo 'Docker is ready ✅'