#!/bin/bash

cp conf/starter.env .env

if [[ $(uname -s) == 'Darwin' ]]; then
    platform=mac
else
    platform=linux
fi

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

PUBLIC_IP=$(curl --silent ifconfig.me)
if [[ "$platform" == 'linux' ]]; then
    VM_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')
    KAFKA_CLUSTER_IP=${VM_IP}
    if [ ! -z "$1" ]; then
        KAFKA_CLUSTER_IP=$1
    fi
    sed -i s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env
    sed -i s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env
    sed -i s/VM_IP=.*/VM_IP=${VM_IP}/g .env
    sed -i s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env
    sed -i s/BROKER_HOST=.*/BROKER_HOST=${KAFKA_CLUSTER_IP}/g .env
    sed -i s/SCHEMA_REGISTRY_HOST=.*/SCHEMA_REGISTRY_HOST=${KAFKA_CLUSTER_IP}/g .env
    sed -i s/CONNECT_HOST=.*/CONNECT_HOST=${KAFKA_CLUSTER_IP}/g .env
    sed -i s/KSQLDB_HOST=.*/KSQLDB_HOST=${KAFKA_CLUSTER_IP}/g .env
    sed -i s/REST_PROXY_HOST=.*/REST_PROXY_HOST=${KAFKA_CLUSTER_IP}/g .env
else
    VM_IP=$(ip route get 8.8.8.8 | ggrep -oP 'src \K[^ ]+')
    sed -e s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env > .env.1
    sed -e s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env.1 > .env.2
    sed -e s/VM_IP=.*/VM_IP=${VM_IP}/g .env.2 > .env.3
    sed -e s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env.3 > .env
    rm .env.*
fi    
