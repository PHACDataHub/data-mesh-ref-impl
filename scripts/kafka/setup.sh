#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

echo 'Creating volumes for zookeeper and broker(s) ...'
for item in vol/zk/data vol/zk/txn-logs vol/broker/data vol/broker2/data vol/broker3/data vol/schema-registry/data
do
    mkdir -p $item;
    sudo chown -R $CURRENT_UID $item;
    sudo chgrp -R $CURRENT_GID $item;
    sudo chmod -R u+rwX,g+rX,o+wrx $item;
    echo $item 'volume is created.'
done
echo 'Volumes for zookeeper and broker(s) created ✅'
echo ''

echo 'Setting permissions for plugins and data folders ...'
for item in kafka-ce/connect/data/error kafka-ce/connect/data/processed kafka-ce/connect/data/unprocessed kafka-ce/plugins 
do
    mkdir -p $item;
    sudo chown -R $CURRENT_UID $item;
    sudo chgrp -R $CURRENT_GID $item;
    sudo chmod -R u+rwX,g+rX,o+wrx $item;
    echo $item 'folder permissions are set.'
done
echo 'Permissions for data & plugins folders set ✅'

