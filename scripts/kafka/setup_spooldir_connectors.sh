#!/bin/bash

connect=localhost:8083
internal_broker=broker:29092
localhost_broker=localhost:9092

echo "Listing all connectors ...";
curl -s ${connect}/connectors | jq '.[]'

echo "Listing all topics ...";
docker exec kafkacat kafkacat -b ${internal_broker} -q -L  -J | jq '.topics[].topic' | sort

key_fields_counties=county_fips
cast_types_counties=population:int32,lat:float32,lng:float32
key_fields_airports=ident
cast_types_airports=lat:float32,lng:float32
key_fields_arptoarp=airport_1,airport_2
cast_types_arptoarp=year:int32,quarter:int32,nsmiles:float32,passengers:float32,fare:float32
key_fields_dailyc19=date,fips
cast_types_dailyc19=cases:int32,deaths:int32

for item in counties airports arptoarp dailyc19 
do
    key_fields_var="key_fields_"${item}
    key_fields="${!key_fields_var}"
    cast_types_var="cast_types_"${item}
    cast_types="${!cast_types_var}"
    echo ${item}${key_fields} ${cast_types}

    curl -i -X PUT -H "Accept:application/json" \
        -H  "Content-Type:application/json" http://${connect}/connectors/spooldir_${item}/config \
        -d '{
            "connector.class":"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
            "topic":"topic_'${item}'",
            "input.path":"/data/unprocessed",
            "finished.path":"/data/processed",
            "error.path":"/data/error",
            "input.file.pattern":"'${item}'\\.csv",
            "schema.generation.enabled":"true",
            "schema.generation.key.fields":"'${key_fields}'",
            "csv.first.row.as.header":"true",
            "transforms":"castTypes",
            "transforms.castTypes.type":"org.apache.kafka.connect.transforms.Cast$Value",
            "transforms.castTypes.spec":"'${cast_types}'"
            }'
done


echo "Listing all connectors ...";
curl -s ${connect}/connectors | jq '.[]'

echo "Listing all topics ...";
OSTYPE=$(uname -s)

if [[ $OSTYPE == 'Linux' ]]; then
    docker exec kafkacat kafkacat -b ${internal_broker} -q -L  -J | jq '.topics[].topic' | sort
fi
if [[ $OSTYPE == 'Darwin' ]]; then
    kcat -b ${localhost_broker} -q -L  -J | jq '.topics[].topic' | sort
fi
