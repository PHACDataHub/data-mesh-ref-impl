------------------------------------------------------------------------------------------
-- docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
------------------------------------------------------------------------------------------

SET 'auto.offset.reset' = 'earliest';

LIST STREAMS;

------------------------------------------------------------------------------------------
--- Creating vaccines_stream from existing topics ----------------------------------------
------------------------------------------------------------------------------------------

PRINT 'vaccine-standards' FROM BEGINNING LIMIT 7;
PRINT 'vaccine-lot-info' FROM BEGINNING LIMIT 7;
SET 'auto.offset.reset' = 'earliest';

DROP STREAM IF EXISTS vaccines_stream;
DROP STREAM IF EXISTS vaccine_standards_stream;
DROP STREAM IF EXISTS vaccine_lot_info_stream;

CREATE STREAM vaccine_standards_stream WITH (KAFKA_TOPIC='vaccine-standards', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);
CREATE STREAM vaccine_lot_info_stream WITH (KAFKA_TOPIC='vaccine-lot-info', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);

CREATE STREAM vaccines_stream WITH (
    KAFKA_TOPIC='vaccines', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    s.ROWKEY AS ROWKEY,
    s.name AS name,
    l.unit_of_sale AS unit_of_sale,
    l.unit_of_use AS unit_of_use
FROM vaccine_standards_stream s
INNER JOIN vaccine_lot_info_stream l
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON s.ROWKEY->vid = l.ROWKEY->vid
EMIT CHANGES;

SELECT * FROM vaccines_stream  EMIT CHANGES LIMIT 7;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Creating persons_stream_<province> from existing topics ------------------------------
------------------------------------------------------------------------------------------

PRINT 'persons-BC' FROM BEGINNING LIMIT 1;
PRINT 'persons-ON' FROM BEGINNING LIMIT 1;
PRINT 'persons-QC' FROM BEGINNING LIMIT 1;
SET 'auto.offset.reset' = 'earliest';

DROP STREAM IF EXISTS persons_stream;
DROP STREAM IF EXISTS persons_stream_BC;
DROP STREAM IF EXISTS persons_stream_ON;
DROP STREAM IF EXISTS persons_stream_QC;

CREATE STREAM persons_stream_BC WITH (KAFKA_TOPIC='persons-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);
CREATE STREAM persons_stream_ON WITH (KAFKA_TOPIC='persons-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);
CREATE STREAM persons_stream_QC WITH (KAFKA_TOPIC='persons-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3);

SELECT * FROM persons_stream_BC  EMIT CHANGES LIMIT 1;
SELECT * FROM persons_stream_ON  EMIT CHANGES LIMIT 1;
SELECT * FROM persons_stream_QC  EMIT CHANGES LIMIT 1;
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM persons_stream WITH (KAFKA_TOPIC='persons', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', PARTITIONS=3, REPLICAS=3)
AS SELECT ROWKEY, 'BC' AS province FROM persons_stream_BC;
INSERT INTO persons_stream SELECT ROWKEY, 'ON' AS province FROM persons_stream_ON;
INSERT INTO persons_stream SELECT ROWKEY, 'QC' AS province FROM persons_stream_QC;

SELECT * FROM persons_stream  EMIT CHANGES LIMIT 3;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Creating vaccination_events_stream_<province> from existing topics -------------------
------------------------------------------------------------------------------------------

PRINT 'vaccination-events-BC' FROM BEGINNING LIMIT 5;
PRINT 'vaccination-events-ON' FROM BEGINNING LIMIT 5;
PRINT 'vaccination-events-QC' FROM BEGINNING LIMIT 6;
SET 'auto.offset.reset' = 'earliest';

DROP STREAM IF EXISTS vaccination_events_stream_BC;
DROP STREAM IF EXISTS vaccination_events_stream_ON;
DROP STREAM IF EXISTS vaccination_events_stream_QC;

CREATE STREAM vaccination_events_stream_BC WITH (
    KAFKA_TOPIC='vaccination-events-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);
CREATE STREAM vaccination_events_stream_ON WITH (
    KAFKA_TOPIC='vaccination-events-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);
CREATE STREAM vaccination_events_stream_QC WITH (
    KAFKA_TOPIC='vaccination-events-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

SELECT * FROM vaccination_events_stream_BC EMIT CHANGES LIMIT 5;
SELECT * FROM vaccination_events_stream_ON EMIT CHANGES LIMIT 5;
SELECT * FROM vaccination_events_stream_QC EMIT CHANGES LIMIT 6;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Creating adverse_effects_stream_<province> from existing topics ----------------------
------------------------------------------------------------------------------------------

PRINT 'adverse-effects-BC' FROM BEGINNING LIMIT 2;
PRINT 'adverse-effects-ON' FROM BEGINNING LIMIT 0;
PRINT 'adverse-effects-QC' FROM BEGINNING LIMIT 3;
SET 'auto.offset.reset' = 'earliest';

DROP STREAM IF EXISTS adverse_effects_stream_BC;
DROP STREAM IF EXISTS adverse_effects_stream_ON;
DROP STREAM IF EXISTS adverse_effects_stream_QC;

CREATE STREAM adverse_effects_stream_BC WITH (
    KAFKA_TOPIC='adverse-effects-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);
CREATE STREAM adverse_effects_stream_ON WITH (
    KAFKA_TOPIC='adverse-effects-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);
CREATE STREAM adverse_effects_stream_QC WITH (
    KAFKA_TOPIC='adverse-effects-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

SELECT * FROM adverse_effects_stream_BC EMIT CHANGES LIMIT 2;
SELECT * FROM adverse_effects_stream_ON EMIT CHANGES LIMIT 0;
SELECT * FROM adverse_effects_stream_QC EMIT CHANGES LIMIT 3;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Filter duplicates in vaccination_events_stream_<province> ----------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS unique_vaccination_events_stream_BC;
DROP STREAM IF EXISTS unique_vaccination_events_stream_ON;
DROP STREAM IF EXISTS unique_vaccination_events_stream_QC;
DROP TABLE IF EXISTS unique_vaccination_events_table_BC DELETE TOPIC;
DROP TABLE IF EXISTS unique_vaccination_events_table_ON DELETE TOPIC;
DROP TABLE IF EXISTS unique_vaccination_events_table_QC DELETE TOPIC;

CREATE TABLE unique_vaccination_events_table_BC WITH (
    KAFKA_TOPIC='unique-vaccination-events-BC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	location,
	COUNT(*) AS count
FROM vaccination_events_stream_BC
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid, location
HAVING COUNT(*) = 1;

CREATE TABLE unique_vaccination_events_table_ON WITH (
    KAFKA_TOPIC='unique-vaccination-events-ON', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	location,
	COUNT(*) AS count
FROM vaccination_events_stream_ON
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid, location
HAVING COUNT(*) = 1;

CREATE TABLE unique_vaccination_events_table_QC WITH (
    KAFKA_TOPIC='unique-vaccination-events-QC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	location,
	COUNT(*) AS count
FROM vaccination_events_stream_QC
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid, location
HAVING COUNT(*) = 1;

PRINT 'unique-vaccination-events-BC' FROM BEGINNING LIMIT 4;
PRINT 'unique-vaccination-events-ON' FROM BEGINNING LIMIT 4;
PRINT 'unique-vaccination-events-QC' FROM BEGINNING LIMIT 5;
SET 'auto.offset.reset' = 'earliest';

SELECT * FROM unique_vaccination_events_table_BC EMIT CHANGES LIMIT 4;
SELECT * FROM unique_vaccination_events_table_ON EMIT CHANGES LIMIT 4;
SELECT * FROM unique_vaccination_events_table_QC EMIT CHANGES LIMIT 5;
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM unique_vaccination_events_stream_BC WITH (
    KAFKA_TOPIC='unique-vaccination-events-BC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

CREATE STREAM unique_vaccination_events_stream_ON WITH (
    KAFKA_TOPIC='unique-vaccination-events-ON', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

CREATE STREAM unique_vaccination_events_stream_QC WITH (
    KAFKA_TOPIC='unique-vaccination-events-QC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

SELECT * FROM unique_vaccination_events_stream_BC EMIT CHANGES LIMIT 4;
SELECT * FROM unique_vaccination_events_stream_ON EMIT CHANGES LIMIT 4;
SELECT * FROM unique_vaccination_events_stream_QC EMIT CHANGES LIMIT 5;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Filter duplicates in adverse_effects_stream_<province> ---------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS unique_adverse_effects_stream_BC;
DROP STREAM IF EXISTS unique_adverse_effects_stream_ON;
DROP STREAM IF EXISTS unique_adverse_effects_stream_QC;
DROP TABLE IF EXISTS unique_adverse_effects_table_BC DELETE TOPIC;
DROP TABLE IF EXISTS unique_adverse_effects_table_ON DELETE TOPIC;
DROP TABLE IF EXISTS unique_adverse_effects_table_QC DELETE TOPIC;

CREATE TABLE unique_adverse_effects_table_BC WITH (
    KAFKA_TOPIC='unique-adverse-effects-BC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	COUNT(*) AS count
FROM adverse_effects_stream_BC
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid
HAVING COUNT(*) = 1;

CREATE TABLE unique_adverse_effects_table_ON WITH (
    KAFKA_TOPIC='unique-adverse-effects-ON', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	COUNT(*) AS count
FROM adverse_effects_stream_ON
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid
HAVING COUNT(*) = 1;

CREATE TABLE unique_adverse_effects_table_QC WITH (
    KAFKA_TOPIC='unique-adverse-effects-QC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT 
	ROWKEY->pid,
	vid,
	EARLIEST_BY_OFFSET(datetime) AS datetime,
	COUNT(*) AS count
FROM adverse_effects_stream_QC
    WINDOW SESSION (2 DAYS)
GROUP BY ROWKEY->pid, vid
HAVING COUNT(*) = 1;

PRINT 'unique-adverse-effects-BC' FROM BEGINNING LIMIT 2;
PRINT 'unique-adverse-effects-ON' FROM BEGINNING LIMIT 0;
PRINT 'unique-adverse-effects-QC' FROM BEGINNING LIMIT 2;
SET 'auto.offset.reset' = 'earliest';

SELECT * FROM unique_adverse_effects_table_BC EMIT CHANGES LIMIT 2;
SELECT * FROM unique_adverse_effects_table_ON EMIT CHANGES LIMIT 0;
SELECT * FROM unique_adverse_effects_table_QC EMIT CHANGES LIMIT 2;
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM unique_adverse_effects_stream_BC WITH (
    KAFKA_TOPIC='unique-adverse-effects-BC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

CREATE STREAM unique_adverse_effects_stream_ON WITH (
    KAFKA_TOPIC='unique-adverse-effects-ON', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

CREATE STREAM unique_adverse_effects_stream_QC WITH (
    KAFKA_TOPIC='unique-adverse-effects-QC', KEY_FORMAT = 'AVRO', VALUE_FORMAT='AVRO',
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
);

SELECT * FROM unique_adverse_effects_stream_BC EMIT CHANGES LIMIT 2;
SELECT * FROM unique_adverse_effects_stream_ON EMIT CHANGES LIMIT 0;
SELECT * FROM unique_adverse_effects_stream_QC EMIT CHANGES LIMIT 2;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Aggregate unique_vaccination_events_stream -------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS unique_vaccination_events_stream DELETE TOPIC;

CREATE STREAM unique_vaccination_events_stream WITH (
    KAFKA_TOPIC='unique-vaccination-events', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT ROWKEY, datetime, 'BC' AS province FROM unique_vaccination_events_stream_BC;
INSERT INTO unique_vaccination_events_stream SELECT ROWKEY, datetime, 'ON' AS province FROM unique_vaccination_events_stream_ON;
INSERT INTO unique_vaccination_events_stream SELECT ROWKEY, datetime, 'QC' AS province FROM unique_vaccination_events_stream_QC;

SELECT * FROM unique_vaccination_events_stream  EMIT CHANGES LIMIT 13;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Aggregate unique_adverse_effects_stream ----------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS unique_adverse_effects_stream DELETE TOPIC;

CREATE STREAM unique_adverse_effects_stream WITH (
    KAFKA_TOPIC='unique-adverse-effects', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT ROWKEY, datetime, 'BC' AS province FROM unique_adverse_effects_stream_BC;
INSERT INTO unique_adverse_effects_stream SELECT ROWKEY, datetime, 'ON' AS province FROM unique_adverse_effects_stream_ON;
INSERT INTO unique_adverse_effects_stream SELECT ROWKEY, datetime, 'QC' AS province FROM unique_adverse_effects_stream_QC;

SELECT * FROM unique_adverse_effects_stream  EMIT CHANGES LIMIT 4;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Make enriched_vaccination_events_stream ----------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_vaccination_events_stream DELETE TOPIC;

CREATE STREAM enriched_vaccination_events_stream WITH (
    KAFKA_TOPIC='enriched-vaccination-events', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    u.ROWKEY,
    u.datetime AS datetime,
    u.province AS province,
    v.ROWKEY->vid AS vaccine_id,
    v.name AS vaccine_name,
    v.unit_of_sale AS vaccine_unit_of_sale,
    v.unit_of_use AS vaccine_unit_of_use
FROM unique_vaccination_events_stream u
INNER JOIN vaccines_stream v
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.ROWKEY->vid = v.ROWKEY->vid
EMIT CHANGES;

SELECT * FROM enriched_vaccination_events_stream  EMIT CHANGES LIMIT 13;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Make enriched_adverse_effects_stream -------------------------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_adverse_effects_stream DELETE TOPIC;

CREATE STREAM enriched_adverse_effects_stream WITH (
    KAFKA_TOPIC='enriched-adverse-effects', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    a.ROWKEY,
    a.datetime AS datetime,
    u.province AS province,
    u.ROWKEY->location
FROM unique_adverse_effects_stream a
INNER JOIN unique_vaccination_events_stream u
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.ROWKEY->vid = u.ROWKEY->vid
    WHERE a.ROWKEY->pid = u.ROWKEY->pid
EMIT CHANGES;

SELECT * FROM enriched_adverse_effects_stream  EMIT CHANGES LIMIT 4;
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM enriched_adverse_effects_stream_with_vaccine WITH (
    KAFKA_TOPIC='enriched-adverse-effects-with-vaccine', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    a.A_ROWKEY,
    a.datetime AS datetime,
    a.province AS province,
    a.location AS location,
    v.ROWKEY->vid AS vaccine_id,
    v.name AS vaccine_name,
    v.unit_of_sale AS vaccine_unit_of_sale,
    v.unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream a
INNER JOIN vaccines_stream v
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->vid = v.ROWKEY->vid
EMIT CHANGES;

SELECT * FROM enriched_adverse_effects_stream_with_vaccine  EMIT CHANGES LIMIT 4;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Filter enriched_vaccination_events_stream_<province> ---------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_vaccination_events_stream_BC DELETE TOPIC;
DROP STREAM IF EXISTS enriched_vaccination_events_stream_ON DELETE TOPIC;
DROP STREAM IF EXISTS enriched_vaccination_events_stream_QC DELETE TOPIC;

CREATE STREAM enriched_vaccination_events_stream_BC WITH (
    KAFKA_TOPIC='enriched-vaccination-events-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    u.U_ROWKEY,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream u
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'BC';

CREATE STREAM enriched_vaccination_events_stream_ON WITH (
    KAFKA_TOPIC='enriched-vaccination-events-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    u.U_ROWKEY,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream u
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'ON';

CREATE STREAM enriched_vaccination_events_stream_QC WITH (
    KAFKA_TOPIC='enriched-vaccination-events-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    u.U_ROWKEY,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream u
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'QC';

SELECT * FROM enriched_vaccination_events_stream_BC  EMIT CHANGES LIMIT 4;
SELECT * FROM enriched_vaccination_events_stream_ON  EMIT CHANGES LIMIT 5;
SELECT * FROM enriched_vaccination_events_stream_QC  EMIT CHANGES LIMIT 4;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Enrich enriched_vaccination_records_stream_<province>_ -------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_vaccination_records_stream_BC DELETE TOPIC;
DROP STREAM IF EXISTS enriched_vaccination_records_stream_ON DELETE TOPIC;
DROP STREAM IF EXISTS enriched_vaccination_records_stream_QC DELETE TOPIC;

CREATE STREAM enriched_vaccination_records_stream_BC WITH (
    KAFKA_TOPIC='enriched-vaccination-records-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    u.U_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream_BC u
INNER JOIN persons_stream_BC p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

CREATE STREAM enriched_vaccination_records_stream_ON WITH (
    KAFKA_TOPIC='enriched-vaccination-records-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    u.U_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream_ON u
INNER JOIN persons_stream_ON p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

CREATE STREAM enriched_vaccination_records_stream_QC WITH (
    KAFKA_TOPIC='enriched-vaccination-records-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    u.U_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    u.datetime AS datetime,
    u.U_ROWKEY->location AS location,
    u.vaccine_id AS vaccine_id,
    u.vaccine_name AS vaccine_name,
    u.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    u.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_vaccination_events_stream_QC u
INNER JOIN persons_stream_QC p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON u.U_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

SELECT * FROM enriched_vaccination_records_stream_BC  EMIT CHANGES LIMIT 4;
SELECT * FROM enriched_vaccination_records_stream_ON  EMIT CHANGES LIMIT 5;
SELECT * FROM enriched_vaccination_records_stream_QC  EMIT CHANGES LIMIT 4;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Filter enriched_adverse_effects_stream_<province> ---------------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_adverse_effects_stream_BC DELETE TOPIC;
DROP STREAM IF EXISTS enriched_adverse_effects_stream_ON DELETE TOPIC;
DROP STREAM IF EXISTS enriched_adverse_effects_stream_QC DELETE TOPIC;

CREATE STREAM enriched_adverse_effects_stream_BC WITH (
    KAFKA_TOPIC='enriched-adverse-effects-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    a.A_ROWKEY,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_with_vaccine a
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'BC';

CREATE STREAM enriched_adverse_effects_stream_ON WITH (
    KAFKA_TOPIC='enriched-adverse-effects-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    a.A_ROWKEY,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_with_vaccine a
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'ON';

CREATE STREAM enriched_adverse_effects_stream_QC WITH (
    KAFKA_TOPIC='enriched-adverse-effects-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_1,
    a.A_ROWKEY,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_with_vaccine a
INNER JOIN persons_stream p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
    WHERE p.province = 'QC';

SELECT * FROM enriched_adverse_effects_stream_BC  EMIT CHANGES LIMIT 2;
SELECT * FROM enriched_adverse_effects_stream_ON  EMIT CHANGES LIMIT 1;
SELECT * FROM enriched_adverse_effects_stream_QC  EMIT CHANGES LIMIT 1;
SET 'auto.offset.reset' = 'earliest';

------------------------------------------------------------------------------------------
--- Enrich enriched_adverse_effects_report_stream_<province>_ ----------------------------
------------------------------------------------------------------------------------------

DROP STREAM IF EXISTS enriched_adverse_effects_report_stream_BC DELETE TOPIC;
DROP STREAM IF EXISTS enriched_adverse_effects_report_stream_ON DELETE TOPIC;
DROP STREAM IF EXISTS enriched_adverse_effects_report_stream_QC DELETE TOPIC;

CREATE STREAM enriched_adverse_effects_report_stream_BC WITH (
    KAFKA_TOPIC='enriched-adverse-effects-report-BC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    a.A_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_BC a
INNER JOIN persons_stream_BC p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

CREATE STREAM enriched_adverse_effects_report_stream_ON WITH (
    KAFKA_TOPIC='enriched-adverse-effects-report-ON', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    a.A_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_ON a
INNER JOIN persons_stream_ON p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

CREATE STREAM enriched_adverse_effects_report_stream_QC WITH (
    KAFKA_TOPIC='enriched-adverse-effects-report-QC', KEY_FORMAT='AVRO', VALUE_FORMAT='AVRO', 
    TIMESTAMP='datetime', TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss', PARTITIONS=3, REPLICAS=3
) AS SELECT
    ROWKEY_2,
    a.A_ROWKEY,
    p.name AS name,
    p.blood_type AS blood_type,
    p.birthday AS birthday,
    p.address AS address,
    a.datetime AS datetime,
    a.location AS location,
    a.vaccine_id AS vaccine_id,
    a.vaccine_name AS vaccine_name,
    a.vaccine_unit_of_sale AS vaccine_unit_of_sale,
    a.vaccine_unit_of_use AS vaccine_unit_of_use
FROM enriched_adverse_effects_stream_QC a
INNER JOIN persons_stream_QC p
	WITHIN 365 DAYS GRACE PERIOD 12 HOURS
	ON a.A_ROWKEY->pid = p.ROWKEY->pid
EMIT CHANGES;

SELECT * FROM enriched_adverse_effects_report_stream_BC EMIT CHANGES LIMIT 2;
SELECT * FROM enriched_adverse_effects_report_stream_ON EMIT CHANGES LIMIT 1;
SELECT * FROM enriched_adverse_effects_report_stream_QC EMIT CHANGES LIMIT 1;
SET 'auto.offset.reset' = 'earliest';