#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

ksql_cli_name=ksqldb-cli

cp conf/kafka-ce/ksql-statements.sql kafka-ce//ksqldb-cli/src/.
cp data/kafka-ce/repair-events.json kafka-ce//ksqldb-cli/test/.
cp data/kafka-ce/repair-events-output.json kafka-ce//ksqldb-cli/test/.

echo "Invoking the tests using the test runner and the statements file ...";
docker exec ksqldb-cli ksql-test-runner -i /opt/app/test/repair-events.json -s /opt/app/src/ksql-statements.sql -o /opt/app/test/repair-events-output.json
echo ''

echo "Test completed ✅";