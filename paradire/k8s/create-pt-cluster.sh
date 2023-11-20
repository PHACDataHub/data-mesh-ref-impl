#!/bin/bash

provinces="ab bc mb nb nl ns nt nu on pe qc sk yt phac"
selected_provinces=($provinces)

echo "Choose an action: 1 for install, 2 for upgrade"
read action_choice

if ! [[ "$action_choice" == "1" || "$action_choice" == "2" ]]; then
    echo "Invalid choice. Please enter '1' for install or '2' for upgrade."
    exit 1
fi

read -p "Enter the number of records you want to generate and upload: " record_count

if ! [[ "$record_count" =~ ^[0-9]+$ ]]; then
    echo "Invalid record count. Please enter a valid number."
    exit 1
fi

for pt in "${selected_provinces[@]}"; do
    cmd="upgrade"
    if [[ "$action_choice" == "1" ]]; then
        cmd="install"
    fi

    if [[ "$pt" == "phac" ]]; then
        helm $cmd "$pt"-province . --namespace="$pt" --create-namespace \
        --set acg.enabled=false \
        --set governance-ui.enabled=false \
        --set hapi-fhir-server.enabled=false \
        --set patient-browser.enabled=false \
        --set cp-kafka-ui.paradire.pt="$pt" \
        --set cp-kafka-job.pt="$pt" \
        --set cp-kafka-job.GCPBucketName="paradire-synthea-data" \
        --set cp-kafka-job.samplingSize="$record_count" \
        --set paradire-ingress.pt="$pt" || exit $?
    else
        # Deploy all components for other provinces
        helm $cmd "$pt"-province . --namespace="$pt" --create-namespace \
        --set cp-kafka-ui.paradire.pt="$pt" \
        --set cp-kafka-job.pt="$pt" \
        --set governance-ui.pt="$pt" \
        --set acg.pt="$pt" \
        --set cp-kafka-job.GCPBucketName="paradire-synthea-data" \
        --set cp-kafka-job.samplingSize="$record_count" \
        --set paradire-ingress.pt="$pt" || exit $?
    fi

done

echo "All tasks completed!"

