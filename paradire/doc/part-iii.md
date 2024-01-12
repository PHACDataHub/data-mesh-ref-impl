[Table of Content](./README.md) | [Prev](./part-ii.md) | [Next](./part-iv.md)

--- 

# [Part III - PT and F clusters in harmony](#part-iii---pt-and-f-clusters-in-harmony)


# Kubernetes Cluster Deployment Script

## Overview
The [`launch_pt_federal_cluster.sh`](../k8s/launch_pt_federal_cluster.sh) script is an automation tool for managing Kubernetes cluster deployments for 13 provinces and a Federal cluster. It leverages Helm, a package manager for Kubernetes, to facilitate the installation, upgrade, and uninstallation of these clusters.

## Prerequisites
- Bash shell.
- Kubernetes and Helm setup.
- Proper access to the target Kubernetes clusters.

## Usage

### Run the Script
Execute the script in a Bash environment:
./launch_pt_federal_cluster.sh


### Select an Action

1. **Install** (`1`):
   - **Action**: Executes `helm install`.
   - **Purpose**: To deploy a new set of Kubernetes resources for a specific province or the Federal cluster. It creates all necessary Kubernetes components if they don't exist.

2. **Upgrade** (`2`):
   - **Action**: Executes `helm upgrade`.
   - **Purpose**: To update an existing deployment with new configurations or updates. This is useful for updating the clusters without disrupting their current state.

3. **Uninstall** (`-1`):
   - **Action**: Executes uninstallation of the Helm release.
   - **Purpose**: To completely remove the deployment from the specified Kubernetes clusters. This includes deleting all resources associated with the deployment.

### Choose Environment (For Install and Upgrade Only)

- **Staging Environment** (`1`):
   - Retrieves Let's Encrypt staging certificates.
   - Suitable for testing and non-production environments.

- **Production Environment** (`2`):
   - Retrieves Let's Encrypt production certificates.
   - Used for live, user-facing deployments.

   The script defaults to the staging environment if an invalid choice is entered.

### Confirm Uninstallation (For Uninstall Only)

- **Confirmation Prompt**:
   - Enter `Y` to proceed with uninstallation.
   - Enter `N` to cancel the process.

   This confirmation step ensures that uninstallation is intentional, preventing accidental deletion of resources.

#### Encrypted Secrets Management

This guide explains how to use the provided script to encrypt Kubernetes secrets using `sops` and Google Cloud Platform (GCP) Key Management Service (KMS).

## Prerequisites

- Ensure that you have `sops` installed on your system. If not, you can install it following the instructions from [Mozilla SOPS GitHub page](https://github.com/mozilla/sops).
- You must have access to a GCP account and the necessary permissions to use the KMS key specified in the script.
- Google Cloud SDK should be installed and configured on your system. You can find instructions on the [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs/install).

Configure GCP KMS Key: The script uses a specific GCP KMS key to encrypt secrets. This key is defined in the script under the variable GCP_KMS_KEY. Ensure this key is correct and you have permissions to access it.

Prepare Your Secrets: Place all your unencrypted Kubernetes secret files in the ./k8s-secrets directory. Make sure this directory exists in your local clone of the repository.

## Add your secret files to this directory
mkdir -p ./k8s-secrets

## Encrypting Secrets
Run the Encryption Script: Execute the script to encrypt your secrets. The script will process each file in the ./k8s-secrets directory and create encrypted versions in the ./k8s-encrypted-secrets directory.

./encrypt-secrets.sh

## Verify Encrypted Secrets: Check the ./k8s-encrypted-secrets directory to ensure that all your secrets are encrypted and stored with the .enc extension.

ls ./k8s-encrypted-secrets

#### Architecture

![The deployed architecture](../k8s/architecture/k8s-paradire.png)

--- 

[Table of Content](./README.md) | [Top](#part-iii) | [Prev](./part-ii.md) | [Next](./part-iv.md)
