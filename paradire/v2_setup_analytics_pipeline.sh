#!/bin/bash

source .env

echo 'Creating constraints and indexes ...'
sudo cp analytics/v2_neo4j/v2_entity_constraints.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/v2_entity_constraints.cql
echo 'Constraints and indexes are created ✅'

if [ ! -z ${PT} ]
    dashboard_file=analytics/v2_neo4j/pt_neodash.json
    dashboard_title="Federal Analytics Platform"
else
    dashboard_file=analytics/v2_neo4j/f_neodash.json
    dashboard_title="${PT} Analytics Platform"
fi
echo Reading dashboard file $dashboard_file
dashboard_content="$(<$dashboard_file)"
dashboard_version="2.4"
dashboard_user="neo4j"
dashboard_uuid=$(cat $dashboard_file | jq '.uuid')

docker exec --interactive --tty neo4j bash -c "echo 'MATCH (n:_Neodash_Dashboard) SET n.date = DATETIME(), n.title = $dashboard_title, n.version=$dashboard_version, n.user=$dashboard_user, n.uuid=$dashboard_uuid, n.content=$dashboard_content RETURN n.date, n.title, n.version, n.user, n.uuid |  cypher-shell -u $NEO4J_USERNAME -p $NEO4J_PASSWORD"