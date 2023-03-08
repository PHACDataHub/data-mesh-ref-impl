#!/bin/bash
set -e

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
OSTYPE=$(uname -s)

service=$1
shift;

echo Deleting volumes for ${service} ...
for item in $@
do
    echo  $item
    sudo rm -rf $item;
done
echo Volumes for ${service} deleted ✅
echo 
