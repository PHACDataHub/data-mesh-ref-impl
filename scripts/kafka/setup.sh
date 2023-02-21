#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

echo 'Creating volumes for zookeeper and broker(s) ...'
for item in kafka-ce/zk/data kafka-ce/zk/txn-logs kafka-ce/broker/data kafka-ce/broker2/data kafka-ce/broker3/data kafka-ce/schema-registry/data
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
for item in kafka-ce/plugins kafka-ce/ksqldb-cli/src kafka-ce/ksqldb-cli/test
do
    mkdir -p $item;
    sudo chown -R $CURRENT_UID $item;
    sudo chgrp -R $CURRENT_GID $item;
    sudo chmod -R u+rwX,g+rX,o+wrx $item;
    echo $item 'folder permissions are set.'
done
echo 'Permissions for data & plugins folders set ✅'

echo 'Setting permissions for spooldir connector folders ...'
for item in kafka-ce/connect/data/spooldir/error kafka-ce/connect/data/spooldir/processed kafka-ce/connect/data/spooldir/unprocessed
do
    mkdir -p $item;
    sudo chown -R $CURRENT_UID $item;
    sudo chgrp -R $CURRENT_GID $item;
    sudo chmod -R u+rwX,g+rX,o+wrx $item;
    echo $item 'folder permissions are set.'
done
echo 'Permissions for spooldir connector folders set ✅'

echo 'Setting permissions for filepulse connector folders ...'
for item in kafka-ce/connect/data/filepulse/xml
do
    mkdir -p $item;
    sudo chown -R $CURRENT_UID $item;
    sudo chgrp -R $CURRENT_GID $item;
    sudo chmod -R u+rwX,g+rX,o+wrx $item;
    echo $item 'folder permissions are set.'
done
echo 'Permissions for filepulse connector folders set ✅'

