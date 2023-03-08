#!/bin/bash

docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 \
    -it -v ./src/nlp/tests:/tests \
    --rm nvcr.io/nvidia/pytorch:23.01-py3 python /tests/train.py