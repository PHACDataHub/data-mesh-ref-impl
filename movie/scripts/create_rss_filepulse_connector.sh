#!/bin/bash

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

./scripts/kafka/list_plugins.sh
./scripts/kafka/list_connectors.sh
./scripts/kafka/list_subjects.sh

entity=screenrant
topic=${entity}-topic
connector=${entity}-filepulse-connector

echo "Creating filepulse connector ..." 

config='{
    "connector.class":"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector",
    "fs.listing.class":"io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing",
    "fs.listing.directory.path":"/data/filepulse/xml",
    "fs.listing.filters":"io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter",
    "fs.listing.interval.ms":10000,
    "fs.cleanup.policy.class": "io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ",
    "file.filter.regex.pattern":".*\\.xml$",
    "offset.strategy":"name",
    "reader.xpath.expression":"/rss/channel/item",
    "reader.xpath.result.type":"NODESET",
    "reader.xml.force.array.on.fields":"category",
    "reader.xml.parser.validating.enabled":true,
    "reader.xml.parser.namespace.aware.enabled":true,
    "filters":"enclosure,content,pubDate,Exclude",
    "filters.enclosure.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter",
    "filters.enclosure.source":"enclosure.url",
    "filters.enclosure.target":"enclosure_url",
    "filters.content.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter",
    "filters.content.field":"encoded",
    "filters.content.target":"content",
    "filters.pubDate.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter",
    "filters.pubDate.field":"pubDate",
    "filters.pubDate.target":"pub_date",
    "filters.Exclude.type":"io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter",
    "filters.Exclude.fields":"enclosure,guid",
    "topic":"'${topic}'",
    "tasks.file.status.storage.bootstrap.servers":"'${broker_internal_host}':'${broker_internal_port}'",
    "tasks.file.status.storage.topic":"connect-file-pulse-status",
    "tasks.reader.class":"io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader",
    "tasks.max": 1,
    "value.connect.schema":"{ \"name\": \"screentrant_rss_value\", \"type\":\"STRUCT\", \"fieldSchemas\": { \"link\":{\"type\":\"STRING\", \"isOptional\":false}, \"pub_date\":{\"type\":\"STRING\", \"isOptional\":false}, \"category\": {\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"content\":{\"type\":\"STRING\", \"isOptional\":false}, \"creator\":{\"type\":\"STRING\", \"isOptional\":false}, \"description\":{\"type\":\"STRING\", \"isOptional\":false}, \"enclosure_url\":{\"type\":\"STRING\", \"isOptional\":false}, \"title\":{\"type\":\"STRING\", \"isOptional\":false} } }"
}'

curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" \
    http://${connect_local_host}:${connect_port}/connectors/${connector}/config \
    -d "${config}"
echo ''
echo ''


if [ "$?" = "1" ]; then
    exit 1
fi

echo "Filepulse connector created ✅";
echo ''

./scripts/kafka/list_connectors.sh
./scripts/kafka/list_topics.sh
./scripts/kafka/list_subjects.sh

cp data/rss/screenrant-rss-*.xml kafka-ce/connect/data/filepulse/xml/.
