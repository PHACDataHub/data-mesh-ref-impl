/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating Vaccination Records
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    'MATCH (immunization:Immunization)
	    WITH immunization ORDER BY immunization.date ASC
	RETURN
        immunization, \"' + event.request_id + '\" AS request_id'
    AS batch_producer,
    'WITH immunization, request_id
    	MATCH (organization:Organization)-[]-(encounter:Encounter)-[:IMMUNIZATION_OF_ENCOUNTER]-(immunization)-[:IMMUNIZATION_OF_PATIENT]-(patient:Patient)
	WITH immunization, organization, encounter, patient, request_id
		CREATE (record:VaccinationRecord)
    		SET record.request_id = request_id,
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
				record.patient_age = 2023 - patient.birth_date.year,
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:VaccinationRecord)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.immunization_date AS immunization_date,
    record.immunization_code AS immunization_code,
    record.immunization_description AS immunization_description,
    record.organization_name AS organization_name,
    record.organization_zip AS organization_zip,
    record.encounter_class AS encounter_class,
    record.encounter_code AS encounter_code,
    record.encounter_description AS encounter_description,
    record.patient_id AS patient_id,
    record.patient_address AS patient_address,
    record.patient_age AS patient_age,
    record.patient_zip AS patient_zip,
    record.patient_gender AS patient_gender,
    record.patient_race AS patient_race,
    record.patient_ethnicity AS patient_ethnicity,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating Patient-Immunization statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    'MATCH (patient:Patient)-[]-(immunization:Immunization)
        WHERE ' + (CASE WHEN event.city IS NOT NULL THEN 'patient.city = \"' + event.city + '\" ' ELSE 'TRUE ' END) + 
    'RETURN
        DISTINCT(patient.zip) AS zip, patient.city AS city, 
        \"' + event.request_id + '\" AS request_id,
        COUNT(immunization) AS immunization_count' 
    AS batch_producer,
    'WITH city, zip, request_id, immunization_count
        CREATE (record:ZipImmunization)
            SET record.request_id = request_id,
                record.city = city,
                record.zip = zip,
                record.immunization_count = immunization_count, 
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:ZipImmunization)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.city AS city,
    record.zip AS zip,
    record.immunization_count AS immunization_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////