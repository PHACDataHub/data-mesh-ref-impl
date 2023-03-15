#!/bin/bash


if [ -z "$1" ] ; then
    echo "Usage ./scripts/get_env_var.sh <variable set by dot_env (.env)>";
    echo "Example: ./scripts/get_env_var.sh VM_IP";
    echo "Example: ./scripts/get_env_var.sh PUBLIC_IP";
    exit 1
fi

source .env 
var=$1
echo ${!var}
