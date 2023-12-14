#!/bin/bash

# Check if sops is installed
if ! command -v sops &> /dev/null; then
    echo "sops is not installed. Please install sops before running this script."
    exit 1
fi

# Set your GCP KMS key
GCP_KMS_KEY="projects/phx-01he5rx4wsv/locations/northamerica-northeast1/keyRings/paradire-secrets/cryptoKeys/paradire-secrets"

# Path to the directories
UNENCRYPTED_DIR="./k8s-secrets"
ENCRYPTED_DIR="./k8s-encrypted-secrets"

# Check if the unencrypted secrets directory exists
if [ ! -d "$UNENCRYPTED_DIR" ]; then
  echo "The directory $UNENCRYPTED_DIR does not exist. Please check the path and try again."
  exit 1
fi

# Check if the encrypted secrets directory exists, create it if it doesn't
if [ ! -d "$ENCRYPTED_DIR" ]; then
  echo "The directory $ENCRYPTED_DIR does not exist. Creating it now."
  mkdir -p "$ENCRYPTED_DIR"
fi

# Encrypting each file
for file in "$UNENCRYPTED_DIR"/*; do
  # Skip directories
  if [[ -d $file ]]; then continue; fi

  # Get the filename from the path
  filename=$(basename "$file")

  # Define the output encrypted file path
  encrypted_file="$ENCRYPTED_DIR/${filename}.enc"

  # Encrypt the file
  if sops --encrypt --gcp-kms "$GCP_KMS_KEY" "$file" > "$encrypted_file"; then
      echo "Encrypted $file to $encrypted_file"
  else
      echo "Failed to encrypt $file"
      exit 1
  fi
  
  echo "Encrypted $file to $encrypted_file"
done

echo "All secrets have been encrypted."



# Recover from reauth related error
# You might get a reauth related error response from third-party apps after a session expires. To resume using these apps, users can sign in to the app again to start a new session.
# Apps that use Application Default Credentials (ADC) with user credentials are considered third-party apps. These credentials are valid only for the configured session length. When that session expires, apps using ADC might also return a reauth related error response. Developers can reauthorize the app by running the 
# gcloud auth application-default login 
# command to obtain new credentials.
# https://support.google.com/a/answer/9368756