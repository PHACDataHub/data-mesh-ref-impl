#!/bin/bash

sudo apt install -y     build-essential
sudo apt install -y gcc-12 make
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 12

sudo update-alternatives --config gcc
sudo update-alternatives --config g++
gcc --version
g++ --version

DRIVER_VERSION=535.54.03

wget "https://us.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"
chmod +x NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
sudo ./NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
rm NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run

nvidia-smi

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

CUDA_VERSION=12.2.0

docker run --rm --gpus all nvidia/cuda:${CUDA_VERSION}-base-ubuntu22.04 nvidia-smi

PYTORCH_VERSION=23.06-py3

docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 \
  -it -v ./src/tests:/tests \
  --rm nvcr.io/nvidia/pytorch:${PYTORCH_VERSION} python /tests/mnist.py
