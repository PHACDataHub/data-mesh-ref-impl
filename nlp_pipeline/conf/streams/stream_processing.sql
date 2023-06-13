------------------------------------------------------------------------------------------
-- docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
--- Creating streams from existing topics ------------------------------------------------
------------------------------------------------------------------------------------------

SET 'auto.offset.reset' = 'earliest';

LIST STREAMS;

DROP STREAM IF EXISTS reviewed_trashed_articles DELETE TOPIC;
DROP STREAM IF EXISTS reviewed_relevant_articles DELETE TOPIC;
DROP STREAM IF EXISTS review_status;
DROP STREAM IF EXISTS pending_review_articles;

CREATE STREAM pending_review_articles WITH (KAFKA_TOPIC='pending-review-articles', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);

CREATE STREAM review_status WITH (KAFKA_TOPIC='review-status', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);

CREATE STREAM reviewed_relevant_articles WITH (
    KAFKA_TOPIC='reviewed-relevant-articles', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3
) AS SELECT
	rs.doc_id,
	pra.folder,
	pra.headline,
	pra.lead_para,
	pra.tail_para,
	pra.lang_id,
	pra.lang_name,
	pra.labels,
	pra.bio_ner,
	pra.ner,
	pra.summary_text
FROM review_status rs
INNER JOIN pending_review_articles pra
	WITHIN 1 DAYS GRACE PERIOD 12 HOURS
	ON rs.doc_id = pra.ROWKEY->doc_id
	WHERE rs.is_relevant = TRUE
EMIT CHANGES;

CREATE STREAM reviewed_trashed_articles WITH (
    KAFKA_TOPIC='review-trashed-articles', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3
) AS SELECT
	rs.doc_id,
	pra.folder,
	pra.headline,
	pra.lead_para,
	pra.tail_para,
	pra.lang_id,
	pra.lang_name,
	pra.labels,
	pra.bio_ner,
	pra.ner,
	pra.summary_text
FROM review_status rs
INNER JOIN pending_review_articles pra
	WITHIN 1 DAYS GRACE PERIOD 12 HOURS
	ON rs.doc_id = pra.ROWKEY->doc_id
	WHERE rs.is_relevant = FALSE
EMIT CHANGES;
