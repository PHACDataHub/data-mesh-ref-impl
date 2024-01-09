#!/bin/bash

NAMESPACES=("phac" "bc" "ab" "mb" "nb" "nl" "ns" "nt" "nu" "on" "pe" "qc" "sk" "yt")

for NAMESPACE in "${NAMESPACES[@]}"; do
    echo "Processing namespace: $NAMESPACE"

    kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
    echo "Labeled namespace $NAMESPACE for Istio injection"

    for deployment in $(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
        echo "Restarting deployment: $deployment"
        kubectl rollout restart deployment/"$deployment" -n "$NAMESPACE"
    done

    # Restart all statefulsets in the namespace
    for statefulset in $(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
        echo "Restarting statefulset: $statefulset"
        kubectl rollout restart statefulset/"$statefulset" -n "$NAMESPACE"
    done
done

echo "All tasks completed!"
