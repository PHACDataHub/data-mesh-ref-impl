#!/bin/bash

source .env

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

connect_container=connect
connect_host=${CONNECT_HOST}
connect_port=${CONNECT_PORT}

has_filepulse=$(./scripts/list_plugins.sh | grep FilePulseSourceConnector)
if [ -z $has_filepulse ]; then
    echo "io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector" plugin not found. Cleanup and restart the Kafka Cluster.
    exit 1
fi

./scripts/list_connectors.sh
./scripts/list_subjects.sh

entity=factiva-articles
topic=${entity}
connector=${entity}-filepulse-connector

echo "Creating filepulse connector ..." 

config='{
    "connector.class":"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector",
    "fs.listing.class":"io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing",
    "fs.listing.directory.path":"/data/filepulse/xml",
    "fs.listing.filters":"io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter",
    "fs.listing.interval.ms": "5000",
    "fs.cleanup.policy.class": "io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ",
    "file.filter.regex.pattern":".*\\.xml$",
    "reader.xpath.expression":"/DistDoc",
    "reader.xml.parser.validating.enabled":false,
    "reader.xml.parser.namespace.aware.enabled":true,
    "reader.filters.ParseXmlDocument.xml.exclude.empty.elements":false,
    "reader.filters.ParseXmlDocument.xml.data.type.inference.enabled":true,
    "reader.xml.exclude.node.attributes":true,
    "filters":"folder,dup_id_trim,dup_id_list,doc_id,title,lead,tail,Exclude,move_head,move_lead,move_tail",
    "filters.folder.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.folder.field":"$.folder",
    "filters.folder.value":"$.SelectData.FolderName",
    "filters.dup_id_trim.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.dup_id_trim.field":"$.dup_id_trim",
    "filters.dup_id_trim.value":"{{ trim($.SelectDedupData.DupList) }}",
    "filters.dup_id_list.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.dup_id_list.field":"$.dup_id_list",
    "filters.dup_id_list.value":"{{ split($.dup_id_trim, '\',\'') }}",
    "filters.doc_id.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.doc_id.field":"$.doc_id",
    "filters.doc_id.value":"$.MetadataPT.DocData.IPDocId",
    "filters.title.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.title.field":"$.head",
    "filters.title.value":"$.ArchiveDoc.Article.HandL.Title.Headline",
    "filters.lead.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.lead.field":"$.lead",
    "filters.lead.value":"$.ArchiveDoc.Article.HandL.LeadPara",
    "filters.tail.type":"io.streamthoughts.kafka.connect.filepulse.filter.AppendFilter",
    "filters.tail.field":"$.tail",
    "filters.tail.value":"$.ArchiveDoc.Article.TailParas",
    "filters.move_head.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter",
    "filters.move_head.source":"head.Para",
    "filters.move_head.target":"headline",
    "filters.move_lead.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter",
    "filters.move_lead.source":"lead.Para",
    "filters.move_lead.target":"lead_para",
    "filters.move_tail.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter",
    "filters.move_tail.source":"tail.Para",
    "filters.move_tail.target":"tail_para",
    "filters.Exclude.type":"io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter",
    "filters.Exclude.fields":"dup_id_trim,SelectData,SelectDedupData,ReplyItem,MetadataPT,ArchiveDoc,AdocTOC",
    "topic":"'${topic}'",
    "tasks.file.status.storage.bootstrap.servers":"'${broker_internal_host}':'${broker_internal_port}'",
    "tasks.file.status.storage.topic":"connect-file-pulse-status",
    "tasks.reader.class":"io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader",
    "tasks.max": 1,
    "value.connect.schema":"{ \"name\": \"factiva_article_value\", \"type\": \"STRUCT\", \"fieldSchemas\": { \"doc_id\":{\"type\":\"STRING\", \"isOptional\":false}, \"dup_id_list\":{\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"folder\":{\"type\":\"STRING\", \"isOptional\":true}, \"headline\":{\"type\":\"STRING\", \"isOptional\":true}, \"lead_para\":{\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"tail_para\":{\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}} } }"
}'


curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" \
    http://${connect_host}:${connect_port}/connectors/${connector}/config \
    -d "${config}"
echo ''
echo ''


if [ "$?" = "1" ]; then
    exit 1
fi

echo "Filepulse connector created ✅";
echo ''

./scripts/list_connectors.sh
./scripts/list_topics.sh
./scripts/list_subjects.sh

files=$(ls -1 factiva_data/*.xml | sort)

for f in $files
do
    cp -v $f kafka-ce/connect/data/filepulse/xml/.
    sleep 5
done

ls -la --time-style=full-iso kafka-ce/connect/data/filepulse/xml/
