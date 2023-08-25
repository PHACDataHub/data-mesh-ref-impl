#!/bin/bash

valid_vms="kafka_cluster neo4j_cluster"

if [ $# -lt 1 ] || [ -z "$(echo ${valid_vms} | grep $1)" ]; then
    echo "Usage: ./run.sh <vm_name>"
    echo "   where vm_name is one of: ${valid_vms}"
    echo "Example: ./run.sh kafka_cluster"
    exit
fi

valid_vm=$1

if [ "$valid_vm" = "kafka_cluster" ] && [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

if [ "$valid_vm" = "kafka_cluster" ]; then
    ./produce_messages.sh who-don-articles data/who/who_dons.tar.gz who_dons-1-142.txt 2836 who-don-key who-don-val
    ./produce_messages.sh do-class-entities data/do/do-classes.tar.gz do-classes.txt 13843 do-class-key do-class-val
fi

if [ "$valid_vm" = "neo4j_cluster" ]; then
    ./create_neo4j_database.sh
fi
