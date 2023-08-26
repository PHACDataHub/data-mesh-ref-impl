#!/bin/bash

if [ ! -d "kafka-ce/zk" ]; then
    echo "The cluster is not setup yet ❌";
    exit 1
fi

./create_neo4j_database.sh

./produce_messages.sh who-don-articles data/who_dons.tar.gz who_dons-1-142.txt 2836 who-don-key who-don-val
./produce_messages.sh do-class-entities data/do-classes.tar.gz do-classes.txt 13843 do-class-key do-class-val
