/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_1
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_1)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.covid_cvx_list AS covid_cvx_list,
    entity.period_length AS period_length,
    entity.number_of_periods AS number_of_periods,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    SPLIT(event.covid_cvx_list, ',') AS covid_cvx_list,
    DATE(even.start_date) AS start_date,
    event.period_length AS period_length,
    event.pt_list AS pt
    UNWIND RANGE(0, event.number_of_periods -1) AS period
WITH
    request_id, pt,
    OPTIONAL MATCH (patient)-[]-(immunization:Immunization)
        WHERE
            immunization.code IN covid_cvx_list AND
            immunization.date >= start_date + DURATION({months: period * period_length}) AND
            immunization.date <= start_date + DURATION({months: (period + 1) * period_length})
WITH
    DISTINCT(patient) AS patient,
    request_id, pt, period_start, period_end,
    COUNT(immunization) AS immunization_count
WITH
    DISTINCT(patient.zip) AS patient_zip,
    request_id, pt, period_start, period_end, 
    CASE
        WHEN immunization_count >= 2 THEN 'Fully vaccinated' 
        WHEN immunization_count = 1 THEN 'One-dosed' 
        ELSE 'Unvaccinated' END AS patient_status, 
    COUNT(*) AS status_count
WITH
    request_id, pt, period_start, period_end, patient_zip, patient_status, status_count
        MATCH (patient:Patient {zip: patient_zip})
WITH 
    request_id, pt, period_start, period_end, patient_zip, patient_status, status_count
    COUNT(patient) AS patient_count
WITH
    request_id, pt, period_start, period_end, patient_zip, patient_status, status_count, patient_count,
    ROUND(status_count*10000.0 / patient_count)/100.0 AS status_percent
    CREATE (n:FAS_1)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.start_date = period_start,
            n.end_date = period_end,
            n.patient_zip = patient_zip,
            n.patient_count = patient_count,
            n.patient_status = patient_status,
            n.status_count = status_count,
            n.status_percent = status_percent,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_1)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.start_date AS start_date,
    entity.end_date AS end_date,
    entity.patient_zip AS patient_zip,
    entity.patient_count AS patient_count,
    entity.patient_status AS patient_status,
    entity.status_count AS status_count,
    entity.status_percent AS status_percent,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_1)
    SET
        n.request_id = event.request_id,
        n.pt = event.pt,
        n.start_date = event.start_date,
        n.end_date = event.end_date,
        n.patient_zip = event.patient_zip,
        n.patient_count = event.patient_count,
        n.patient_status = event.patient_status,
        n.status_count = event.status_count,
        n.status_percent = event.status_percent,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_2
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_2)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.cvx_maps AS cvx_maps,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    event.cvx_maps AS cvx_maps,
    entity.pt_list AS pt
WITH
    request_id, pt, cvx_maps, KEYS(cvx_maps) AS cvx_codes
        MATCH (patient:Patient)
WITH 
    patient, request_id, pt, cvx_maps
        OPTIONAL MATCH (patient)-[]-(immunization:Immunization)
            WHERE immunization.code IN cvx_codes
WITH 
    DISTINCT(patient) AS patient, request_id, pt, cvx_maps, cvx_codes,
    COLLECT([immunization.code, immunization.date]) AS immunizations
WITH 
    patient, request_id, pt, cvx_codes,
    REDUCE(codes=[], e IN immunizations | codes + [e[0]]) AS administered_codes,
    REDUCE(codes=[], e IN immunizations |
        CASE
            WHEN patient.birth_date + DURATION({months: apoc.map.get(cvx_maps, e[0])}) < e[1]
            THEN codes + [e[0]] ELSE codes END
    ) AS missed_schedule_codes
WITH
    patient, request_id, pt, 
    [e IN cvx_codes WHERE NOT(e IN administered_codes)] + missed_schedule_codes
    AS missing_doses
WITH 
    DISTINCT(patient.zip) AS patient_zip,
    request_id, pt,
    COUNT(*) AS patient_count,
    COLLECT(missing_doses) AS list_of_missing_doses
WITH
    request_id, pt, patient_zip, patient_count,
    apoc.coll.sort(apoc.coll.toSet(apoc.coll.flatten(codes))) AS missing_doses
WITH
    request_id, pt, patient_zip, patient_count, missing_doses
    CREATE (n:FAS_2)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.patient_zip = patient_zip,
            n.patient_count = patient_count,
            n.missing_doses = missing_doses,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_2)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.patient_zip AS patient_zip,
    entity.patient_count AS patient_count,
    entity.missing_doses AS missing_doses,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_2)
    SET n.request_id = event.request_id,
        n.pt = event.pt,
        n.patient_zip = event.patient_zip,
        n.patient_count = event.patient_count,
        n.missing_doses = event.missing_doses, 
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_3
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_3)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.cvx_list AS cvx_list,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    SPLIT(event.cvx_list, ',') AS cvx_list,
    event.pt_list AS pt
WITH
    request_id, pt,
    MATCH (patient:Patient)-[]-(:Immunization)-[]-(:Encounter)-[]-(organization:Organization)
        WHERE immunization.code IN covid_cvx_list
WITH
    request_id, pt,
    patient.zip AS zip,
    POINT.DISTANCE(patient.location, organization.location) AS distance,
    organization.name AS organization
WITH
    DISTINCT([zip, organization]) AS zip_org,
    request_id, pt,
    SUM(distance)/COUNT(distance) AS average_distance
WITH
    request_id, pt, 
    zip_org[0] AS patient_zip,
    zip_org[1] AS organization_name,
    average_distance
    CREATE (n:FAS_3)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.patient_zip = patient_zip,
            n.organization_name = organization_name,
            n.average_distance = average_distance,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_3)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.patient_zip AS patient_zip,
    entity.organization_name AS organization_name,
    entity.average_distance AS average_distance,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_3)
    SET n.request_id = event.request_id,
        n.pt = event.pt,
        n.patient_zip = event.patient_zip,
        n.organization_name = event.organization_name,
        n.average_distance = event.average_distance,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Process events from far_4 topic into FAR_4 nodes
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_4)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.cvx_list AS cvx_list,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    SPLIT(event.cvx_list, ',') AS cvx_list,
    event.pt_list AS pt
WITH
    request_id, pt,
    MATCH (patient:Patient)-[]-(:Immunization)-[]-(:Encounter)-[]-(organization:Organization)
        WHERE immunization.code IN covid_cvx_list
WITH
    DISTINCT([patient.zip, organization.name]) AS zip_org,
    request_id, pt,
    COUNT(*) AS vaccination_count
WITH
    request_id, pt, 
    zip_org[0] AS patient_zip,
    zip_org[1] AS organization_name,
    vaccination_count
    CREATE (n:FAS_4)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.patient_zip = patient_zip,
            n.organization_name = organization_name,
            n.vaccination_count = vaccination_count,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_4)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.patient_zip AS patient_zip,
    entity.organization_name AS organization_name,
    entity.vaccination_count AS vaccination_count,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_4)
    SET n.request_id = event.request_id,
        n.pt = event.pt,
        n.patient_zip = event.patient_zip,
        n.organization_name = event.organization_name,
        n.vaccination_count = event.vaccination_count,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_5
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_5)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    'MATCH (immunization:Immunization)
	    WITH immunization ORDER BY immunization.date ASC
	RETURN
        immunization, \"' + event.request_id + '\" AS request_id, \"' + event.pt + '\" AS pt'
    AS batch_producer,
    'WITH immunization, request_id, pt
    	MATCH (organization:Organization)-[]-(encounter:Encounter)-[:IMMUNIZATION_OF_ENCOUNTER]-(immunization)-[:IMMUNIZATION_OF_PATIENT]-(patient:Patient)
	WITH immunization, organization, encounter, patient, request_id, pt
		CREATE (record:VaccinationRecord)
    		SET 
                record.request_id = request_id,
                record.pt = pt,
    			record.immunization_date = TOSTRING(immunization.date),
				record.immunization_code = immunization.code,
				record.immunization_description = immunization.description,
				record.organization_name = organization.name,
				record.organization_zip = organization.zip,
				record.encounter_class = encounter.encounter_class,
				record.encounter_code = encounter.code,
				record.encounter_description = encounter.description,
				record.patient_id = patient.patient_id,
				record.patient_address = patient.address,
				record.patient_birth_date = TOSTRING(patient.birth_date),
                record.patient_alive =  CASE WHEN patient.death_date IS NULL THEN TRUE ELSE FALSE END,
				record.patient_zip = patient.zip,
				record.patient_gender = patient.gender,
				record.patient_race = patient.race,
				record.patient_ethnicity = patient.ethnicity,
				record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_5)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.immunization_date AS immunization_date,
    entity.immunization_code AS immunization_code,
    entity.immunization_description AS immunization_description,
    entity.organization_name AS organization_name,
    entity.organization_zip AS organization_zip,
    entity.encounter_class AS encounter_class,
    entity.encounter_code AS encounter_code,
    entity.encounter_description AS encounter_description,
    entity.patient_id AS patient_id,
    entity.patient_address AS patient_address,
    entity.patient_birth_date AS patient_birth_date,
    entity.patient_alive AS patient_alive,
    entity.patient_zip AS patient_zip,
    entity.patient_gender AS patient_gender,
    entity.patient_race AS patient_race,
    entity.patient_ethnicity AS patient_ethnicity,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_5)
    SET
        n.request_id = event.request_id,
        n.pt = event.pt,
        n.immunization_date = event.immunization_date,
        n.immunization_code = event.immunization_code,
        n.immunization_description = event.immunization_description,
        n.organization_name = event.organization_name,
        n.organization_zip = event.organization_zip,
        n.encounter_class = event.encounter_class,
        n.encounter_code = event.encounter_code,
        n.encounter_description = event.encounter_description,
        n.patient_id = event.patient_id,
        n.patient_address = event.patient_address,
        n.patient_birth_date = event.patient_birth_date,
        n.patient_alive = event.patient_alive,
        n.patient_zip = event.patient_zip,
        n.patient_gender = event.patient_gender,
        n.patient_race = event.patient_race,
        n.patient_ethnicity = event.patient_ethnicity,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_6
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_6)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.code_list AS code_list,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    event.pt_list AS pt
WITH
    request_id, pt
    MATCH (condition:Condition)
        WHERE NOT(condition.code IN ['314529007', '160903007', '160904001'])
WITH
    DISTINCT(condition.description) AS condition_description, 
    request_id, pt,
    COUNT(*) AS condition_count
    CREATE (n:FAS_6)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.condition_description = condition_description,
            n.condition_count = condition_count,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_6)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.condition_description AS condition_description,
    entity.condition_count AS condition_count,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_6)
    SET
        n.request_id = event.request_id,
        n.pt = event.pt,
        n.condition_description = event.condition_description,
        n.condition_count = event.condition_count,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_7
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_7)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    event.pt_list AS pt
WITH
    request_id, pt
    MATCH (medication:Medication)
WITH
    DISTINCT(medication.reason_description) AS medication_reason_description
    request_id, pt,
    COUNT(*) AS medication_reason_count
    CREATE (n:FAS_7)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.medication_reason_description = medication_reason_description,
            n.medication_reason_count = medication_reason_count,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_7)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.medication_reason_description AS medication_reason_description,
    entity.medication_reason_count AS medication_reason_count,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_7)
    SET n.request_id = event.request_id,
        n.medication_reason_description = event.medication_reason_description,
        n.medication_reason_count = event.medication_reason_count,
        n.pt = event.pt,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_8
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_8)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    event.pt_list AS pt
WITH
    request_id, pt
    MATCH (procedure:Procedure)
WITH
    DISTINCT(procedure.description) AS procedure_description
    request_id, pt,
    COUNT(*) AS procedure_count
    CREATE (n:FAS_8)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.procedure_description = procedure_description,
            n.procedure_count = procedure_count,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_8)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.procedure_description AS procedure_description,
    entity.procedure_count AS procedure_count,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_8)
    SET 
        n.request_id = event.request_id,
        n.pt = event.pt,
        n.procedure_description = event.procedure_description,
        n.procedure_count = event.procedure_count,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAR_9
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAR_9)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.cvx_maps AS cvx_maps,
    entity.pt_list AS pt_list,
    entity.timestamp AS timestamp,
    entity.doc AS doc;
//
// PAP: (sink connector) Kafka event -> Neo4j entity
//
WITH
    event.request_id AS request_id,
    event.cvx_maps AS cvx_maps,
    entity.pt_list AS pt
WITH
    request_id, pt, cvx_maps, KEYS(cvx_maps) AS cvx_codes
        MATCH (patient:Patient)
WITH 
    patient, request_id, pt, cvx_maps
        OPTIONAL MATCH (patient)-[]-(immunization:Immunization)
            WHERE immunization.code IN cvx_codes
WITH 
    DISTINCT(patient) AS patient, request_id, pt, cvx_maps, cvx_codes,
    COLLECT([immunization.code, immunization.date]) AS immunizations
WITH 
    patient, request_id, pt, cvx_codes,
    REDUCE(codes=[], e IN immunizations | codes + [e[0]]) AS administered_codes,
    REDUCE(codes=[], e IN immunizations |
        CASE
            WHEN patient.birth_date + DURATION({months: apoc.map.get(cvx_maps, e[0])}) < e[1]
            THEN codes + [e[0]] ELSE codes END
    ) AS missed_schedule_codes
WITH
    patient, request_id, pt, 
    [e IN cvx_codes WHERE NOT(e IN administered_codes)] + missed_schedule_codes
    AS missing_doses
WITH 
    DISTINCT(patient.zip) AS patient_zip,
    request_id, pt,
    COUNT(*) AS patient_count,
    COLLECT(missing_doses) AS list_of_missing_doses
WITH
    request_id, pt, patient_zip, patient_count,
    apoc.coll.sort(apoc.coll.toSet(apoc.coll.flatten(codes))) AS missing_doses
WITH
    request_id, pt, patient_zip, patient_count, missing_doses
    OPTIONAL MATCH (patient)-[]-(:Immunization)-[]-(:Encounter)-[]-(organization:Organization)
        WHERE patient.zip = patient_zip
WITH
    request_id, pt, patient_zip, patient_count, missing_doses, COLLECT(DISTINCT(organization)) AS organizations
WITH
    request_id, pt, patient_zip, patient_count, missing_doses, organizations
    OPTIONAL MATCH (immunization:Immunization)-[]-(:Encounter)-[]-(organization:Organization)
        WHERE immunization.code IN missing_doses AND organization IN organizations
WITH
    request_id, pt, patient_zip, patient_count, missing_doses, COLLECT(DISTINCT(organization.name)) AS organization_list
    CREATE (n:FAS_9)
        SET
            n.request_id = request_id,
            n.pt = pt,
            n.patient_zip = patient_zip,
            n.patient_count = patient_count,
            n.missing_doses = missing_doses,
            n.organization_list = CASE WHEN SIZE(organization_list) > 0 THEN TOSTRING(apoc.coll.sort(organization_list)) ELSE '' END,
            n.timestamp = apoc.date.currentTimestamp();
//
// PAP: (source connector) Neo4j entity -> Kafka event
//
MATCH (entity:FAS_9)
    WHERE entity.timestamp > $lastCheck
RETURN
    entity.request_id AS request_id,
    entity.pt AS pt,
    entity.patient_zip AS patient_zip,
    entity.patient_count AS patient_count,
    entity.missing_doses AS missing_doses,
    entity.organization_list AS organization_list,
    entity.timestamp AS timestamp;
//
// FAP: (sink connector) Kafka event -> Neo4j entity
//
CREATE (n:FAS_9)
    SET 
        n.request_id = event.request_id,
        n.pt = event.pt,
        n.patient_zip = event.patient_zip,
        n.patient_count = event.patient_count,
        n.missing_doses = event.missing_doses, 
        n.organization_list = event.organization_list,
        n.timestamp = event.timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
