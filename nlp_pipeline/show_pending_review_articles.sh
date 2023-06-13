#!/bin/bash

sink_topic=pending-review-articles
sink_pk_fields=doc_id
sink_table=pending_review

echo Find all articles in table ${sink_table} from sink topic ${sink_topic}
docker exec -it postgres psql -U postgres -d postgres -c 'SELECT '${sink_pk_fields}' FROM '${sink_table}; 
echo ''

