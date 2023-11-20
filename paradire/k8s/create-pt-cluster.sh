#!/bin/bash


provinces="ab bc mb nb nl ns nt nu on pe qc sk yt"

# Get user input for number of records
read -p "Enter the number of records you want to generate and upload: " record_count

# Validate record count
if ! [[ "$record_count" =~ ^[0-9]+$ ]]; then
    log "Invalid record count. Please enter a valid number."
    exit 1
fi

# Ask the user for provinces
echo "Enter the province abbreviations separated by space (e.g., ab bc mb nb nl ns nt nu on pe qc sk yt). Type 'all' for all provinces."
read -a selected_provinces

if [[ "${selected_provinces[0]}" == "all" ]]; then
    selected_provinces=($provinces)
fi

# Sequentially generate and upload data for the selected provinces
for pt in "${selected_provinces[@]}"; do
    if [[ ! " $provinces " =~ " $pt " ]]; then
        log "Invalid province abbreviation: $pt. Skipping."
        continue
    fi

    helm install "$pt"-province . --namespace="$pt" \
    --create-namespace \
    --set cp-kafka-ui.paradire.pt="$pt" \
    --set cp-kafka-job.samplingSize="$record_count" \
    --set cp-kafka-job.pt="$pt" \
    --set cp-kafka-job.GCPBucketName="paradire-synthea-data" || exit $?
    
done

echo "All tasks completed!"