#!/bin/bash

if [ "${pt^^}" = "PHAC" ]; then
    ./federal-cluster.sh
else
    if [ "$CRON_JOB" = "false" ]; then
        ./pt-cluster.sh
    else
        ./pt-cluster-cron.sh
    fi
fi
