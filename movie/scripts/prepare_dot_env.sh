#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/prepare_dot_env.sh <mode>";
    exit 1
fi

if [ "$1" = "create" ]; then
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)
    VM_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')
    PUBLIC_IP=$(curl --silent ifconfig.me)

    sed -i s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env
    sed -i s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env
    sed -i s/VM_IP=.*/VM_IP=${VM_IP}/g .env
    sed -i s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env
else
    sed -i s/CURRENT_UID=.*/CURRENT_UID=/g .env
    sed -i s/CURRENT_GID=.*/CURRENT_GID=/g .env
    sed -i s/VM_IP=.*/VM_IP=/g .env
    sed -i s/PUBLIC_IP=.*/PUBLIC_IP=/g .env
fi
