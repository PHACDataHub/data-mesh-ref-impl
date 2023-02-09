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

echo "Listing all connectors ...";
curl -s -X GET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo "List all topics ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''

echo "Receiving messages from ${topic_cdc} ...";
docker exec -it ${broker_container_name} /bin/kafka-console-consumer \
    --topic ${topic_cdc} --from-beginning --max-messages ${no_messages} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} | tail -n 1
echo ''
echo "Read total ${no_messages} messages ✅";
