#!/bin/bash

provinces="phac bc on"
selected_provinces=($provinces)

echo "Choose an action: 1 for install, 2 for upgrade, -1 for uninstall"
read action_choice

if ! [[ "$action_choice" == "1" || "$action_choice" == "2" || "$action_choice" == "-1" ]]; then
    echo "Invalid choice. Please enter '1' for install, '2' for upgrade, or '-1' for uninstall."
    exit 1
fi

encrypted_secrets_dir="./k8s-encrypted-secrets"
secrets_files=("hapi-fhir-postgres-secret.yaml.enc" "kafka-ui-secret.yaml.enc" "neo4j-secret.yaml.enc")

if ! helm plugin list | grep -q secrets; then
    echo "Helm Secrets plugin is not installed. Installing it now..."
    helm plugin install https://github.com/jkroepke/helm-secrets --version v3.11.0
    if [ $? -ne 0 ]; then
        echo "Failed to install Helm Secrets plugin. Exiting."
        exit 1
    fi
    echo "Helm Secrets plugin installed successfully."
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
    cron_schedule=$(echo "$cron_schedule" | sed 's/\*/\\*/g')

    cmd="upgrade"
    if [[ "$action_choice" == "1" ]]; then
        cmd="install"
    fi

    secrets_args=""
    for file in "${secrets_files[@]}"; do
        full_path="$encrypted_secrets_dir/$file"
        if [[ -f "$full_path" ]]; then
            secrets_args+="-f $full_path "
        else
            echo "Warning: Secret file not found: $full_path"
        fi
    done

    load_balancer_ip=$(gcloud compute addresses describe "$pt-ingress-ip" --format="get(address)" --region northamerica-northeast1)
    # Check if the IP was successfully retrieved
    if [ -z "$load_balancer_ip" ]; then
        echo "Failed to fetch load balancer IP for $pt. Exiting."
        exit 1
    fi

    if [[ "$pt" == "phac" ]]; then
        chart_name="$pt"
        helm_command="helm secrets $cmd \"$chart_name\" . --namespace=\"$pt\" --create-namespace $secrets_args"
        additional_sets="--set acg.enabled=false \
        --set governance-ui.enabled=false \
        --set hapi-fhir-server.enabled=false \
        --set patient-browser.enabled=false \
        --set cp-kafka-cj.enabled=false \
        --set cp-kafka-ui.paradire.pt=\"$pt\" \
        --set cp-kafka-job.pt=\"$pt\" \
        --set neo4j.envSetting=\"$env_setting\" \
        --set neo4j.paradire.pt=\"$pt\" \
        --set neodash.paradire.pt=\"$pt\" \
        --set neodash-designer.paradire.pt=\"$pt\" \
        --set paradire-ingress.loadBalancerIP=\"$load_balancer_ip\" \
        --set paradire-ingress.envSetting=\"$env_setting\" \
        --set paradire-ingress.pt=\"$pt\""

        # Debugging output
        # echo "Executing command: $helm_command $additional_sets"
        eval $helm_command $additional_sets || exit $?
    else
        # Deploy all components for other provinces
        chart_name="$pt-province"
        helm_command="helm secrets $cmd \"$chart_name\" . --namespace=\"$pt\" --create-namespace $secrets_args"
        additional_sets="--set cp-kafka-ui.paradire.pt=\"$pt\" \
        --set cp-kafka-job.pt=\"$pt\" \
        --set governance-ui.pt=\"$pt\" \
        --set neodash.paradire.pt=\"$pt\" \
        --set neodash-designer.paradire.pt=\"$pt\" \
        --set acg.pt=\"$pt\" \
        --set cp-kafka-cj.enabled=true \
        --set cp-kafka-cj.cronSchedule=\"$cron_schedule\" \
        --set cp-kafka-cj.pt=\"$pt\" \
        --set streaming-ui.enabled=true \
        --set cp-kafka-cj.GCPBucketName=\"paradire-synthea-data\" \
        --set cp-kafka-job.GCPBucketName=\"paradire-synthea-data\" \
        --set neo4j.envSetting=\"$env_setting\" \
        --set hapi-fhir-server.paradire.pt=\"$pt\" \
        --set neo4j.paradire.pt=\"$pt\" \
        --set patient-browser.paradire.pt=\"$pt\" \
        --set paradire-ingress.envSetting=\"$env_setting\" \
        --set paradire-ingress.loadBalancerIP=\"$load_balancer_ip\" \
        --set paradire-ingress.pt=\"$pt\""

        # Debugging output
        # echo "Executing command: $helm_command $additional_sets"
        eval $helm_command $additional_sets || exit $?
    fi

    # Increment the start time by 20 minutes for the next province
    ((start_minute += 30))
done

echo "All tasks completed!"
