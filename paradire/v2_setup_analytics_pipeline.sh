#!/bin/bash

source .env

echo 'Creating constraints and indexes ...'
sudo cp analytics/v2_neo4j/v2_entity_constraints.cql neo4j/import/.
docker exec -u ${NEO4J_USERNAME} --interactive --tty  neo4j cypher-shell -u ${NEO4J_USERNAME} -p ${NEO4J_PASSWORD} --file /import/v2_entity_constraints.cql
echo 'Constraints and indexes are created ✅'

if [ ${PT} = "F" ]; then
    dashboard_file=f_neodash.json
    dashboard_title="Federal Analytics Platform"
else
    dashboard_file=pt_neodash.json
    dashboard_title="${PT} Analytics Platform"
fi

sudo cp analytics/v2_neo4j/$dashboard_file neo4j/import/.
sudo sed -i 's/BC Analytics Platform/$dashboard_title/g' .env

echo Reading dashboard file $dashboard_file
dashboard_version=2.4
dashboard_user=neo4j
dashboard_uuid=$(cat analytics/v2_neo4j/$dashboard_file | jq '.uuid')

docker exec --interactive --tty neo4j bash -c "echo 'CALL apoc.load.json(\"file:///$dashboard_file\") YIELD value AS content MERGE (n:_Neodash_Dashboard) SET n.date = DATETIME(), n.title = \"$dashboard_title\", n.version=\"$dashboard_version\", n.user=\"$dashboard_user\", n.uuid=$dashboard_uuid, n.content=apoc.convert.toJson(content) RETURN n.date, n.title, n.version, n.user, n.uuid' |  cypher-shell -u $NEO4J_USERNAME -p $NEO4J_PASSWORD"