#!/bin/bash

timeout=600
echo ''

zookeeper=zookeeper:2181
echo "Wait for ${zookeeper} ...";
docker exec -it zookeeper cub zk-ready $zookeeper $timeout > /dev/null
echo "${zookeeper} is ready ✅";
echo ''

for item in broker:29092 broker2:29094 broker3:29096
do
    broker=$item
    echo "Wait for ${broker} ...";
    docker exec -it zookeeper cub kafka-ready -b $broker 1 $timeout > /dev/null
    echo "${broker} is ready ✅";
    echo ''
done

schema_registry_host=schema-registry
schema_registry_port=8081
echo "Wait for ${schema_registry_host}:${schema_registry_port} ...";
docker exec -it zookeeper cub sr-ready $schema_registry_host $schema_registry_port $timeout > /dev/null
echo "${schema_registry_host}:${schema_registry_port} is ready ✅";
echo ''

connect_host=connect
connect_port=8083
echo "Wait for ${connect_host}:${connect_port} ...";
docker exec -it zookeeper cub connect-ready $connect_host $connect_port $timeout > /dev/null
echo "${connect_host}:${connect_port} is ready ✅";
echo ''

# rest_proxy_host=rest-proxy
# rest_proxy_port=8082
# echo "Wait for ${rest_proxy_host}:${rest_proxy_port} ...";
# docker exec -it zookeeper cub kr-ready $rest_proxy_host $rest_proxy_port $timeout > /dev/null
# echo "${rest_proxy_host}:${rest_proxy_port} is ready ✅";
# echo ''

# ksqldb_server_host=ksqldb-server
# ksqldb_server_port=8088
# echo "Wait for ${ksqldb_server_host}:${ksqldb_server_port} ...";
# docker exec -it zookeeper cub ksql-server-ready $ksqldb_server_host $ksqldb_server_port $timeout > /dev/null
# echo "${ksqldb_server_host}:${ksqldb_server_port} is ready ✅";
# echo ''

# control_center_host=control-center
# control_center_port=9021
# echo "Wait for ${control_center_host}:${control_center_port} ...";
# docker exec -it zookeeper cub control-center-ready $control_center_host $control_center_port $timeout > /dev/null
# echo "${control_center_host}:${control_center_port} is ready ✅";
# echo ''

echo "Kafka cluster is ready ✅";
