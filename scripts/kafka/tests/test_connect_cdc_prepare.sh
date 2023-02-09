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

echo "Start mysql ...";
docker compose -f docker-compose-mysql.yml up -d
./scripts/neo4j/wait_for_it.sh mysql 60
echo ''

echo "Writing database records ...";
sleep 10
docker exec -i mysql mysql -u root -pdebezium mysql < conf/kafka-ce/grant-access.sql
sleep 10
docker exec -i mysql mysql -u mysqluser -pmysqlpw < conf/kafka-ce/create-db.sql
echo "Database records written ✅";
echo ''

echo "Listing all available plugins ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connector-plugins |jq '.[].class'
echo ''

echo "Listing all connectors ...";
curl -s -XGET http://${connect_local_host}:${connect_port}/connectors | jq '.[]'
echo ''

echo "List all topics ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} --list;
echo ''

echo "Creating ${connector_cdc} connector ..." 
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
    http://${connect_local_host}:${connect_port}/connectors/ \
    -d @${connector_json}
echo ''
echo ''

sleep 5

echo "Preparation done ✅";