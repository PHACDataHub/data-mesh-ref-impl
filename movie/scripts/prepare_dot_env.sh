#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage ./scripts/prepare_dot_env.sh <mode>";
    exit 1
fi

if [[ $(uname -s) == 'Darwin' ]]; then
    platform=mac
else
    platform=linux
fi

if [ "$1" = "create" ]; then
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)

    PUBLIC_IP=$(curl --silent ifconfig.me)
    if [[ "$platform" == 'linux' ]]; then
        VM_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')
        sed -i s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env
        sed -i s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env
        sed -i s/VM_IP=.*/VM_IP=${VM_IP}/g .env
        sed -i s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env
    else
        VM_IP=$(ip route get 8.8.8.8 | ggrep -oP 'src \K[^ ]+')
        sed -e s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env > .env.1
        sed -e s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env.1 > .env.2
        sed -e s/VM_IP=.*/VM_IP=${VM_IP}/g .env.2 > .env.3
        sed -e s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env.3 > .env
        rm .env.*
    fi    
else
    if [[ "$platform" == 'linux' ]]; then
        sed -i s/CURRENT_UID=.*/CURRENT_UID=/g .env
        sed -i s/CURRENT_GID=.*/CURRENT_GID=/g .env
        sed -i s/VM_IP=.*/VM_IP=/g .env
        sed -i s/PUBLIC_IP=.*/PUBLIC_IP=/g .env
    else
        sed -e s/CURRENT_UID=.*/CURRENT_UID=/g .env > .env.1
        sed -e s/CURRENT_GID=.*/CURRENT_GID=/g .env.1 > .env.2
        sed -e s/VM_IP=.*/VM_IP=/g .env.2 > .env.3
        sed -e s/PUBLIC_IP=.*/PUBLIC_IP=/g .env.3 > .env
        rm .env.*
    fi
fi
