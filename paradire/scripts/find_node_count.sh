#!/bin/bash

source .env

echo "Waiting for all nodes imported ... "

NODE_COUNT=$(docker exec --interactive --tty neo4j bash -c "echo 'MATCH (n) RETURN COUNT(n) AS c' |  cypher-shell -u neo4j -p phac@2023  | tail -n 1 | tr -d '\n'")

while [ "$NODE_COUNT" -lt "$1" ]
do
    NODE_COUNT=$(docker exec --interactive --tty neo4j bash -c "echo 'MATCH (n) RETURN COUNT(n) AS c' |  cypher-shell -u neo4j -p phac@2023  | tail -n 1 | tr -d '\n'")
    echo $NODE_COUNT
    sleep 10
done

echo "${NODE_COUNT} nodes were imported ✅";
