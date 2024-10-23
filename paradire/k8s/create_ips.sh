#!/bin/bash

pts=(on bc phac)

# Process each PT/phac
for pt in "${pts[@]}"; do
    gcloud compute addresses create $pt-cluster-ip --global
done
