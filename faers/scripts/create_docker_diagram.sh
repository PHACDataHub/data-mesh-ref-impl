#!/bin/bash

docker run -u $(id -u) --rm -it --name dcv -v $(pwd):/input  pmsipilot/docker-compose-viz render -f -m image docker-compose.yml -o img/docker-compose.png