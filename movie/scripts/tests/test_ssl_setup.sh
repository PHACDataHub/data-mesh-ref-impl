#!/bin/bash
set -e

source .env

openssl s_client -CAfile ${SECRETS_FOLDER}/ca.crt -connect ${HOSTNAME}:${BROKER_LOCAL_PORT} -tls1_3 -showcerts
