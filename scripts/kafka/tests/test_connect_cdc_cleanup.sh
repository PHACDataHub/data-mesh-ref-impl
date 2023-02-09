#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092
connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=8083

access_sql=conf/kafka-ce/grant-access.sql
data_sql=conf/kafka-ce/create-db.sql
connector_json=conf/kafka-ce/register-mysql.json

entity=counties
topic_cdc=mysqldb.geo.counties
connector_cdc=connector-${entity}

mysql_host=mysql
mysql_port=3306
mysql_root_pass=debezium
mysql_user=mysqluser
mysql_pass=mysqlpw
database=geo
table_name=${entity}
no_messages=10

echo "Delete connector ..." 
curl --silent -X DELETE http://${connect_local_host}:${connect_port}/connectors/${connector_cdc} | jq .[]
echo ${connector_cdc} "connector deleted ✅";

echo "Shutting down mysql ...";
docker compose -f docker-compose-mysql.yml down
echo "mysql shutdown ✅";

echo "Deleting ${topic_cdc} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --delete --topic ${topic_cdc} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port}
echo ${topic_cdc} "deleted ✅";
echo ''
