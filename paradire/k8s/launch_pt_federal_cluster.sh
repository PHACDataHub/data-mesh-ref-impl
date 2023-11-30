#!/bin/bash

provinces="phac bc ab mb nb nl ns nt nu on pe qc sk yt"
selected_provinces=($provinces)

echo "Choose an action: 1 for install, 2 for upgrade, -1 for uninstall"
read action_choice

if ! [[ "$action_choice" == "1" || "$action_choice" == "2" || "$action_choice" == "-1" ]]; then
    echo "Invalid choice. Please enter '1' for install, '2' for upgrade, or '-1' for uninstall."
    exit 1
fi

env_setting="production"

# if [[ "$action_choice" == "1" || "$action_choice" == "2" ]]; then
#     echo "Choose the environment: 1 for staging, 2 for production"
#     read env_choice

#     if [[ "$env_choice" == "2" ]]; then
#         env_setting="production"
#     elif [[ "$env_choice" != "1" ]]; then
#         echo "Invalid choice. Defaulting to staging environment."
#     fi
# fi

if [[ "$action_choice" == "-1" ]]; then
    read -p "Are you sure you want to proceed with uninstallation? (Y/N): " confirm_response
    if [[ "$confirm_response" =~ ^[Yy]$ ]]; then
        for pt in "${selected_provinces[@]}"; do
            helm uninstall "$pt"-province --namespace="$pt"
            kubectl delete namespace "$pt" --force --grace-period=0 --wait=False
        done
        echo "Uninstallation completed."
        exit 0
    else
        echo "Uninstallation canceled."
        exit 0
    fi
fi

start_hour=17
start_minute=0

for pt in "${selected_provinces[@]}"; do

    # Calculate cron schedule
    cron_minute=$((start_minute % 60))
    cron_hour=$start_hour
    if (( cron_minute == 0 && start_minute != 0 )); then
        ((cron_hour++))
    fi
    cron_schedule="${cron_minute} ${cron_hour} * * *"

    cmd="upgrade"
    if [[ "$action_choice" == "1" ]]; then
        cmd="install"
    fi

    if [[ "$pt" == "phac" ]]; then
        helm $cmd "$pt" . --namespace="$pt" --create-namespace \
        --set acg.enabled=false \
        --set governance-ui.enabled=false \
        --set hapi-fhir-server.enabled=false \
        --set patient-browser.enabled=false \
        --set cp-kafka-cj.enabled=false \
        --set cp-kafka-ui.paradire.pt="$pt" \
        --set cp-kafka-job.pt="$pt" \
        --set neo4j.envSetting="$env_setting" \
        --set neo4j.paradire.pt="$pt" \
        --set neodash.paradire.pt="$pt" \
        --set neodash-designer.paradire.pt="$pt" \
        --set paradire-ingress.envSetting="$env_setting" \
        --set paradire-ingress.pt="$pt" || exit $?
    else
        # Deploy all components for other provinces
        helm $cmd "$pt"-province . --namespace="$pt" --create-namespace \
        --set cp-kafka-ui.paradire.pt="$pt" \
        --set cp-kafka-job.pt="$pt" \
        --set governance-ui.pt="$pt" \
        --set neodash.paradire.pt="$pt" \
        --set neodash-designer.paradire.pt="$pt" \
        --set acg.pt="$pt" \
        --set cp-kafka-cj.cronSchedule="$cron_schedule" \
        --set cp-kafka-cj.pt="$pt" \
        --set cp-kafka-cj.enabled=false \
        --set cp-kafka-cj.GCPBucketName="paradire-synthea-data" \
        --set cp-kafka-job.GCPBucketName="paradire-synthea-data" \
        --set neo4j.envSetting="$env_setting" \
        --set hapi-fhir-server.paradire.pt="$pt" \
        --set neo4j.paradire.pt="$pt" \
        --set patient-browser.paradire.pt="$pt" \
        --set paradire-ingress.envSetting="$env_setting" \
        --set paradire-ingress.pt="$pt" || exit $?
    fi

    # Increment the start time by 20 minutes for the next province
    ((start_minute += 30))
done

echo "All tasks completed!"
