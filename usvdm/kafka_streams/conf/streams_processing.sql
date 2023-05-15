------------------------------------------------------------------------------------------
-- docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
--- Creating streams from existing topics ------------------------------------------------
------------------------------------------------------------------------------------------

SET 'auto.offset.reset' = 'earliest';

-- PRINT persons FROM BEGINNING LIMIT 3;
-- PRINT vaccines FROM BEGINNING LIMIT 7;
-- PRINT 'vaccination-events' FROM BEGINNING LIMIT 16;
-- PRINT 'adverse-effects' FROM BEGINNING LIMIT 5;

LIST STREAMS;

DROP STREAM IF EXISTS persons_stream;
DROP STREAM IF EXISTS vaccines_stream;
DROP STREAM IF EXISTS vaccination_events_stream;
DROP STREAM IF EXISTS adverse_effects_stream;

CREATE STREAM persons_stream WITH (
    KAFKA_TOPIC='persons',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    PARTITIONS=1
);
-- SELECT * FROM persons_stream  EMIT CHANGES LIMIT 3;

CREATE STREAM vaccines_stream WITH (
    KAFKA_TOPIC='vaccines',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    PARTITIONS=1
);
-- SELECT * FROM vaccines_stream  EMIT CHANGES LIMIT 3;

CREATE STREAM vaccination_events_stream WITH (
    KAFKA_TOPIC='vaccination-events',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
);
-- SELECT * FROM vaccination_events_stream  EMIT CHANGES LIMIT 16;

CREATE STREAM adverse_effects_stream WITH (
    KAFKA_TOPIC='adverse-effects',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
);
-- SELECT * FROM adverse_effects_stream EMIT CHANGES LIMIT 5;

------------------------------------------------------------------------------------------
--- Filter duplicates in streams ---------------------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS unique_vaccination_events_stream;
DROP TABLE IF EXISTS unique_vaccination_events_table DELETE TOPIC;

DROP STREAM IF EXISTS unique_adverse_effects_stream;
DROP TABLE IF EXISTS unique_adverse_effects_table DELETE TOPIC;

CREATE TABLE unique_vaccination_events_table WITH (
    KAFKA_TOPIC='unique-vaccination-events',
   	KEY_FORMAT = 'AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
) AS SELECT 
	ves.ROWKEY->pid,
	ves.ROWKEY->vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	location,
	COUNT(*) AS count
FROM vaccination_events_stream ves
WINDOW SESSION (2 DAYS)
GROUP BY ves.ROWKEY->pid, ves.ROWKEY->vid, location
HAVING COUNT(*) = 1;
-- PRINT 'unique-vaccination-events' FROM BEGINNING LIMIT 13;
-- SELECT * FROM unique_vaccination_events_table EMIT CHANGES LIMIT 13;

CREATE STREAM unique_vaccination_events_stream WITH (
    KAFKA_TOPIC='unique-vaccination-events',
	KEY_FORMAT = 'AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
);
-- SELECT * FROM unique_vaccination_events_stream EMIT CHANGES LIMIT 13;

CREATE TABLE unique_adverse_effects_table WITH (
    KAFKA_TOPIC='unique-adverse-effects',
   	KEY_FORMAT = 'AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
) AS SELECT 
	aes.ROWKEY->pid,
	aes.ROWKEY->vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	COUNT(*) AS count
FROM adverse_effects_stream aes
WINDOW SESSION (2 DAYS)
GROUP BY aes.ROWKEY->pid, aes.ROWKEY->vid
HAVING COUNT(*) = 1;
-- SELECT * FROM unique_adverse_effects_table EMIT CHANGES LIMIT 4;
-- PRINT 'unique-adverse-effects' FROM BEGINNING LIMIT 4;

CREATE STREAM unique_adverse_effects_stream WITH (
    KAFKA_TOPIC='unique-adverse-effects',
	KEY_FORMAT = 'AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
);
-- SELECT * FROM unique_adverse_effects_stream EMIT CHANGES LIMIT 4;

------------------------------------------------------------------------------------------
--- Output adverse_effects_report --------------------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS adverse_effects_report DELETE TOPIC;

CREATE STREAM adverse_effects_report WITH (
    KAFKA_TOPIC='adverse-effects-report',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='aes_datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss',
    PARTITIONS=1
) AS SELECT *
FROM unique_adverse_effects_stream aes
INNER JOIN unique_vaccination_events_stream ves
	WITHIN 1 DAYS GRACE PERIOD 12 HOURS
	ON aes.ROWKEY->pid = ves.ROWKEY->pid
EMIT CHANGES;

------------------------------------------------------------------------------------------
--- Output vaccination_records -----------------------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS vaccination_records DELETE TOPIC;

CREATE STREAM vaccination_records WITH (
    KAFKA_TOPIC='vaccination-records',
    KEY_FORMAT='AVRO',
    VALUE_FORMAT='AVRO',
    TIMESTAMP='ves_datetime',
    TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss'
) AS SELECT *
FROM unique_vaccination_events_stream ves
INNER JOIN persons_stream ps
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON ps.ROWKEY->pid = ves.ROWKEY->pid
INNER JOIN vaccines_stream vs
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON vs.ROWKEY->vid = ves.ROWKEY->vid
EMIT CHANGES;

------------------------------------------------------------------------------------------
--- Show results  ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

SELECT * FROM adverse_effects_report EMIT CHANGES LIMIT 4;

SELECT * FROM vaccination_records EMIT CHANGES LIMIT 13;
