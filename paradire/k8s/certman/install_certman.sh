#!/bin/bash

# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm install   cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.13.2   --set installCRDs=true

kubectl apply -f ./issuer-lets-encrypt.yaml
