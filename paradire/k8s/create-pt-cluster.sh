#!/bin/bash

provinces="ab bc mb nb nl ns nt nu on pe qc sk yt"
selected_provinces=($provinces) # Automatically select all 13 provinces

# Get user input for action: 1 for install, 2 for upgrade
echo "Choose an action: 1 for install, 2 for upgrade"
read action_choice

# Validate action input
if ! [[ "$action_choice" == "1" || "$action_choice" == "2" ]]; then
    echo "Invalid choice. Please enter '1' for install or '2' for upgrade."
    exit 1
fi

# Get user input for number of records in every case
read -p "Enter the number of records you want to generate and upload: " record_count

# Validate record count
if ! [[ "$record_count" =~ ^[0-9]+$ ]]; then
    echo "Invalid record count. Please enter a valid number."
    exit 1
fi

# Sequentially process data for all provinces
for pt in "${selected_provinces[@]}"; do
    # Determine whether to install or upgrade
    if [[ "$action_choice" == "1" ]]; then
        cmd="install"
    elif [[ "$action_choice" == "2" ]]; then
        cmd="upgrade"
    fi

    # kubectl -n $pt delete ingress/paradire-ingress

    helm $cmd "$pt"-province . --namespace="$pt" \
    --create-namespace \
    --set cp-kafka-ui.paradire.pt="$pt" \
    --set cp-kafka-job.samplingSize="$record_count" \
    --set cp-kafka-job.pt="$pt" \
    --set governance-ui.pt="$pt" \
    --set acg.pt="$pt" \
    --set paradire-ingress.pt="$pt" \
    --set cp-kafka-job.GCPBucketName="paradire-synthea-data" || exit $?

done

echo "All tasks completed!"
