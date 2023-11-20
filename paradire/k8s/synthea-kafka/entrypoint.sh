#!/bin/bash

# Check the pt environment variable
if [ "$pt" != "phac" ]; then
    ./pt-cluster.sh
else
    ./federal-cluster.sh
fi
