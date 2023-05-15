#!/bin/bash

timeout=600
echo ''

source .env

zookeeper=zookeeper:${ZOOKEEPER_CLIENT_PORT}
echo "Wait for ${zookeeper} ...";
docker exec -it zookeeper cub zk-ready $zookeeper $timeout > /dev/null
echo "${zookeeper} is ready ✅";
echo ''

# for item in broker:${BROKER_INTERNAL_PORT} broker2:${BROKER2_INTERNAL_PORT} broker3:${BROKER3_INTERNAL_PORT}
for item in broker:${BROKER_INTERNAL_PORT}
do
    broker=$item
    echo "Wait for ${broker} ...";
    docker exec -it zookeeper cub kafka-ready -b $broker 1 $timeout > /dev/null
    echo "${broker} is ready ✅";
    echo ''
done

schema_registry_host=schema-registry
schema_registry_port=${SCHEMA_REGISTRY_PORT}
echo "Wait for ${schema_registry_host}:${schema_registry_port} ...";
docker exec -it zookeeper cub sr-ready $schema_registry_host $schema_registry_port $timeout > /dev/null
echo "${schema_registry_host}:${schema_registry_port} is ready ✅";
echo ''

# for item in connect connect2 connect3
for item in connect
do
    connect_host=$item
    connect_port=${CONNECT_PORT}
    echo "Wait for ${connect_host}:${connect_port} ...";
    docker exec -it zookeeper cub connect-ready $connect_host $connect_port $timeout > /dev/null
    echo "${connect_host}:${connect_port} is ready ✅";
    echo ''
done

ksqldb_server_host=ksqldb-server
ksqldb_server_port=${KSQLDB_PORT}
echo "Wait for ${ksqldb_server_host}:${ksqldb_server_port} ...";
docker exec -it zookeeper cub ksql-server-ready $ksqldb_server_host $ksqldb_server_port $timeout > /dev/null
echo "${ksqldb_server_host}:${ksqldb_server_port} is ready ✅";
echo ''

# rest_proxy_host=rest-proxy
# rest_proxy_port=${REST_PROXY_PORT}
# echo "Wait for ${rest_proxy_host}:${rest_proxy_port} ...";
# docker exec -it zookeeper cub kr-ready $rest_proxy_host $rest_proxy_port $timeout > /dev/null
# echo "${rest_proxy_host}:${rest_proxy_port} is ready ✅";
# echo ''

echo "Kafka cluster is ready ✅";
