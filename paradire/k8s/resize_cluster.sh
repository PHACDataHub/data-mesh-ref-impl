#!/bin/bash

read -p "Enter 0 to shut down or 1 to restart the cluster: " user_input

CLUSTER_NAME="paradire-cluster"
NODE_POOL="pool-1"
REGION="northamerica-northeast1-a"
EXPECTED_NODE_COUNT=10

NAMESPACES=("phac" "bc" "on")

scale_deployments() {
    scale_factor=$1
    for NAMESPACE in "${NAMESPACES[@]}"; do
        for deployment in $(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
            echo "Scaling deployment: $deployment to $scale_factor"
            kubectl scale deployment "$deployment" --replicas=$scale_factor -n "$NAMESPACE"
        done
    done
}

scale_statefulsets() {
    if [ "$1" == "0" ]; then
        scale_factor=0
    else
        for NAMESPACE in "${NAMESPACES[@]}"; do
            kubectl scale statefulset cp-kafka --replicas=4 -n "$NAMESPACE"
            kubectl scale statefulset cp-zookeeper --replicas=3 -n "$NAMESPACE"
        done
        return
    fi

    for NAMESPACE in "${NAMESPACES[@]}"; do
        for statefulset in $(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
            echo "Scaling statefulset: $statefulset to $scale_factor"
            kubectl scale statefulset "$statefulset" --replicas=$scale_factor -n "$NAMESPACE"
        done
    done
}

resize_cluster() {
    new_size=$1
    echo "Resizing the cluster $CLUSTER_NAME to $new_size nodes..."
    gcloud container clusters resize "$CLUSTER_NAME" --num-nodes=$new_size --node-pool="$NODE_POOL" --region="$REGION" --quiet
}

wait_for_nodes() {
    EXPECTED_NODE_COUNT=10
    count=0
    while [ "$count" -lt "$EXPECTED_NODE_COUNT" ]; do
        echo "Waiting for all nodes to be ready..."
        sleep 10
        count=$(kubectl get nodes -o=jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
        echo "Current ready nodes: $count"
    done
    echo "All nodes are ready."
}

wait_for_zero_replicas() {
    for NAMESPACE in "${NAMESPACES[@]}"; do
        # Wait for Deployments to scale down to 0
        for deployment in $(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
            while : ; do
                replicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
                readyReplicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
                if [ "$replicas" = "0" ] && ( [ -z "$readyReplicas" ] || [ "$readyReplicas" = "0" ] ); then
                    echo "Deployment $deployment in namespace $NAMESPACE has scaled down."
                    break
                else
                    echo "Waiting for deployment $deployment in namespace $NAMESPACE to scale down (Ready Replicas: ${readyReplicas:-0}, Desired Replicas: $replicas)"
                    sleep 5
                fi
            done
        done

        # Wait for StatefulSets to scale down to 0
        for statefulset in $(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
            while : ; do
                replicas=$(kubectl get statefulset "$statefulset" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
                readyReplicas=$(kubectl get statefulset "$statefulset" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
                if [ "$replicas" = "0" ] && ( [ -z "$readyReplicas" ] || [ "$readyReplicas" = "0" ] ); then
                    echo "Statefulset $statefulset in namespace $NAMESPACE has scaled down."
                    break
                else
                    echo "Waiting for statefulset $statefulset in namespace $NAMESPACE to scale down (Ready Replicas: ${readyReplicas:-0}, Desired Replicas: $replicas)"
                    sleep 5
                fi
            done
        done
    done
}

if [ "$user_input" == "0" ]; then
    echo "Shutting down the cluster..."
    scale_statefulsets 0
    scale_deployments 0
    wait_for_zero_replicas
    resize_cluster 0
elif [ "$user_input" == "1" ]; then
    echo "Restarting the cluster..."
    resize_cluster 10
    wait_for_nodes
    scale_statefulsets 1
    scale_deployments 1
else
    echo "Invalid input"
fi

echo "Operation completed!"
