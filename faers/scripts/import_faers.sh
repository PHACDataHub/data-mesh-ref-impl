#!/bin/bash

if [ -z "$1" ]; then
    year=2022
else
    year=$1
fi

if [ -z "$2" ]; then
    quarter=Q4
else
    quarter=$2
fi

source .env

connect_container=connect
connect_internal_host=connect
connect_local_host=localhost
connect_port=${CONNECT_PORT}

./scripts/kafka/list_connect_plugins.sh

./scripts/kafka/list_connectors.sh

no_messages=10

echo 'Copying FAERS data for spooldir connector ...'
src_file=data/genc/NCIt-GENC_Terminology.txt
des_file=kafka-ce/connect/data/spooldir/unprocessed/GENC-$RANDOM.txt
cp $src_file $des_file; 
echo $src_file is copied as $des_file.
for item in DEMO DRUG INDI OUTC REAC RPSR THER
do
    src_file=data/faers/${year}${quarter}/ASCII/${item}${year:(-2)}${quarter}.txt
    des_file=kafka-ce/connect/data/spooldir/unprocessed/${item}-$RANDOM.txt
    cp $src_file $des_file;
    echo $src_file is copied as $des_file.
done
echo 'Data for spooldir copied ✅'
echo ''

for item in DEMO DRUG INDI OUTC REAC RPSR THER GENC
do
    topic=faers-$(echo $item | tr '[:upper:]' '[:lower:]')
    connector=${topic}

    key_schema_file=conf/json/${topic}-key.json
    key_schema=$(cat $key_schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )

    val_schema_file=conf/json/${topic}-val.json
    val_schema=$(cat $val_schema_file | sed 's/\t/ /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | sed 's/\"/\\"/g' )

    separator_char=36
    if [ "${item}" = "GENC" ]; then
        separator_char=9
    fi

    data='{
        "connector.class":"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
        "topic":"'${topic}'",
        "input.path":"/data/spooldir/unprocessed",
        "finished.path":"/data/spooldir/processed",
        "error.path":"/data/spooldir/error",
        "input.file.pattern":"^'${item}'-[0-9]+\\.txt",
        "csv.separator.char":'${separator_char}',
        "csv.first.row.as.header":true,
        "key.schema":"'${key_schema}'",
        "value.schema":"'${val_schema}'"
    }'

    curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" \
        http://${connect_local_host}:${connect_port}/connectors/${connector}/config \
        -d "${data}"
    echo ''
    echo ''
done

./scripts/kafka/list_connectors.sh

./scripts/kafka/list_topics.sh

./scripts/kafka/list_subjects.sh
