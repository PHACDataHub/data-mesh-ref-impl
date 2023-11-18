#!/bin/bash

pts=(ab bc mb nb nl nt ns nu on pe qc sk yt phac)

# Process each PT/phac
for pt in "${pts[@]}"; do
    gcloud compute addresses create $pt-cluster-ip --global
done
