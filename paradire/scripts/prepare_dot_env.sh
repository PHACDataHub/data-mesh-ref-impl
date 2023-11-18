#!/bin/bash

cp conf/starter.env .env

if [[ $(uname -s) == 'Darwin' ]]; then
    platform=mac
else
    platform=linux
fi

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

VM_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')
PUBLIC_IP=$(curl --silent ifconfig.me)

if [ -z "$1" ]; then
    PT=F
else 
    PT=$1
fi

LOCAL_KAFKA_CLUSTER_IP=${PUBLIC_IP}

if [ ! -z "$2" ]; then
    REMOTE_KAFKA_CLUSTER_IP=$2
fi

if [[ "$platform" == 'linux' ]]; then
    sed -i s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env
    sed -i s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env
    sed -i s/VM_IP=.*/VM_IP=${VM_IP}/g .env
    sed -i s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env
    sed -i s/BROKER_HOST=.*/BROKER_HOST=${LOCAL_KAFKA_CLUSTER_IP}/g .env
    sed -i s/SCHEMA_REGISTRY_HOST=.*/SCHEMA_REGISTRY_HOST=${LOCAL_KAFKA_CLUSTER_IP}/g .env
    sed -i s/CONNECT_HOST=.*/CONNECT_HOST=${LOCAL_KAFKA_CLUSTER_IP}/g .env
    sed -i s/KSQLDB_HOST=.*/KSQLDB_HOST=${LOCAL_KAFKA_CLUSTER_IP}/g .env
    sed -i s/REST_PROXY_HOST=.*/REST_PROXY_HOST=${LOCAL_KAFKA_CLUSTER_IP}/g .env
    sed -i s/PT=.*/PT=${PT}/g .env
    if [ ! -z "$REMOTE_KAFKA_CLUSTER_IP" ]; then
        sed -i s/F_ZOOKEEPER_HOST=.*/F_ZOOKEEPER_HOST=${REMOTE_KAFKA_CLUSTER_IP}/g .env
        sed -i s/F_BROKER_HOST=.*/F_BROKER_HOST=${REMOTE_KAFKA_CLUSTER_IP}/g .env
        sed -i s/F_SCHEMA_REGISTRY_HOST=.*/F_SCHEMA_REGISTRY_HOST=${REMOTE_KAFKA_CLUSTER_IP}/g .env
    fi
else
    VM_IP=$(ip route get 8.8.8.8 | ggrep -oP 'src \K[^ ]+')
    sed -e s/CURRENT_UID=.*/CURRENT_UID=${CURRENT_UID}/g .env > .env.1
    sed -e s/CURRENT_GID=.*/CURRENT_GID=${CURRENT_GID}/g .env.1 > .env.2
    sed -e s/VM_IP=.*/VM_IP=${VM_IP}/g .env.2 > .env.3
    sed -e s/PUBLIC_IP=.*/PUBLIC_IP=${PUBLIC_IP}/g .env.3 > .env
    rm .env.*
fi    
