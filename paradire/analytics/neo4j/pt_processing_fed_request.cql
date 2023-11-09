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
				record.patient_age = CASE WHEN patient.death_date IS NULL THEN 2023 - patient.birth_date.year ELSE patient.death_date.year - patient.birth_date.year END,
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
                record.patient_city = city,
                record.patient_zip = zip,
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
    record.patient_city AS patient_city,
    record.patient_zip AS patient_zip,
    record.immunization_count AS immunization_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating Top-K Immunization per Zip Code statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    'MATCH (immunization:Immunization)
        WITH DISTINCT(immunization.code) AS code, COUNT(immunization) AS count ORDER BY count DESC LIMIT ' 
        + (CASE WHEN event.k IS NOT NULL THEN TOSTRING(event.k) + ' ' ELSE '5 ' END) +
    'WITH COLLECT(code) AS codes
        MATCH (patient:Patient)-[]-(immunization:Immunization)
            WHERE immunization.code IN codes
    RETURN patient.zip AS zip, immunization.code AS code, COUNT(immunization) AS count, \"' 
    + event.request_id + '\" AS request_id'
    AS batch_producer,
    'WITH zip, code, count, request_id
        CREATE (record:TopKImmunization)
            SET record.request_id = request_id,
                record.patient_zip = zip,
                record.immunization_code = code,
                record.immunization_count = count, 
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:TopKImmunization)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.patient_zip AS patient_zip,
    record.immunization_code AS immunization_code,
    record.immunization_count AS immunization_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating PatientCvxOrg statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    CASE WHEN event.term IS NOT NULL 
        THEN ['immunization.description CONTAINS \"' + event.term + '\"']
        ELSE [] END AS conditions
WITH event,
    CASE WHEN event.code_list IS NOT NULL
        THEN conditions + ['immunization.code IN [' + apoc.text.join([e IN apoc.text.split(event.code_list, ',') | '\"' + e + '\"'], ', ') + ']'] 
        ELSE conditions + [] END AS conditions
WITH event,
    CASE WHEN SIZE(conditions) > 0 THEN ' WHERE ' + apoc.text.join(conditions, ' AND ') + ' ' ELSE '' END AS where_condition
WITH event,
    'MATCH (patient:Patient)-[]-(immunization:Immunization)-[]-(:Encounter)-[]-(organization:Organization)'
    + where_condition + 
    'WITH DISTINCT([patient, organization]) AS po, COLLECT(DISTINCT(immunization.code)) AS code_list, COUNT(*) AS immunization_count
    RETURN po[0] AS patient, po[1] AS organization, code_list, immunization_count, \"' 
    + event.request_id + '\" AS request_id'
    AS batch_producer,
    'WITH patient, organization, code_list, immunization_count, request_id
        CREATE (record:PatientCvxOrg)
            SET record.request_id = request_id,
                record.patient_id = patient.patient_id,
                record.patient_birth_date = TOSTRING(patient.birth_date.year),
                record.patient_gender = patient.gender, 
                record.patient_zip = patient.zip, 
                record.code_list = apoc.text.join(code_list, \",\"), 
                record.immunization_count = immunization_count, 
                record.organization_name = organization.name, 
                record.organization_zip = organization.zip, 
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:PatientCvxOrg)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.patient_id AS patient_id,
    record.patient_birth_date AS patient_birth_date,
    record.patient_gender AS patient_gender,
    record.patient_zip AS patient_zip,
    record.code_list AS code_list,
    record.immunization_count AS immunization_count,
    record.organization_name AS organization_name,
    record.organization_zip AS organization_zip,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating CityYearTopProc statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    'city: \"' + event.city + '\"' AS city_condition,
    'WHERE procedure.code IN [' + apoc.text.join([e IN [event.procedure_1, event.procedure_2, event.procedure_3] | '\"' + e + '\"'], ', ') + '] ' AS where_condition
WITH event,
    'MATCH (organization:Organization {' + city_condition + '})-[]-(:Encounter)-[]-(procedure:Procedure) '
    + where_condition + 
    'WITH DISTINCT(procedure.start.year) AS year, COLLECT(DISTINCT(procedure)) AS procedures, \"' 
    + event.request_id + 
    '\" AS request_id, \"' 
    + event.city + 
    '\" AS city RETURN city, year, procedures, request_id ORDER BY year'
    AS batch_producer,
    'WITH city, year, procedures, request_id
        CREATE (record:CityYearTopProc)
            SET record.request_id = request_id,
                record.organization_city = city,
                record.year = year,
                record.procedure_1 = SIZE([e IN procedures WHERE e.code = \"' + event.procedure_1 + '\"]),
                record.procedure_2 = SIZE([e IN procedures WHERE e.code = \"' + event.procedure_2 + '\"]),
                record.procedure_3 = SIZE([e IN procedures WHERE e.code = \"' + event.procedure_3 + '\"]),
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:CityYearTopProc)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.organization_city AS organization_city,
    record.year AS year,
    record.procedure_1 AS procedure_1,
    record.procedure_2 AS procedure_2,
    record.procedure_3 AS procedure_3,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating PtOrgMed statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    CASE WHEN event.state IS NOT NULL 
        THEN ' {state: \"' + event.state + '\"}'
        ELSE '' END AS state_condition
WITH event,
    'MATCH (organization:Organization' + state_condition + ')-[]-(:Encounter)-[]-(medication:Medication) 
    RETURN organization, COUNT(DISTINCT(medication)) AS count, \"' 
    + event.request_id + 
    '\" AS request_id' 
    AS batch_producer,
    'WITH organization, count, request_id
        CREATE (record:PtOrgMed)
            SET record.request_id = request_id,
                record.organization_city = organization.city,
                record.organization_state = organization.state,
                record.organization_name = organization.name,
                record.medication_count = count,
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:PtOrgMed)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.organization_state AS organization_state,
    record.organization_city AS organization_city,
    record.organization_name AS organization_name,
    record.medication_count AS medication_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating CityOrgPatient statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    CASE WHEN event.city IS NOT NULL 
        THEN ' {city: \"' + event.city + '\"}'
        ELSE '' END AS city_condition
WITH event,
    'MATCH (organization:Organization' + city_condition + ')-[]-(:Encounter)-[]-(patient:Patient)
    RETURN organization, COUNT(DISTINCT(patient)) AS count, \"' 
    + event.request_id + 
    '\" AS request_id' 
    AS batch_producer,
    'WITH organization, count, request_id
        CREATE (record:CityOrgPatient)
            SET record.request_id = request_id,
                record.organization_city = organization.city,
                record.organization_name = organization.name,
                record.patient_count = count,
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:CityOrgPatient)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.organization_city AS organization_city,
    record.organization_name AS organization_name,
    record.patient_count AS patient_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating CityOrgPatientVisit statistics
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
WITH event,
    CASE WHEN event.city IS NOT NULL 
        THEN ' {city: \"' + event.city + '\"}'
        ELSE '' END AS city_condition
WITH event,
    'MATCH (organization:Organization' + city_condition + ')-[]-(:Encounter)-[]-(patient:Patient)
    WITH DISTINCT([organization, patient]) AS op, COUNT(*) AS count
    WITH op[0] AS organization, op[1] AS patient, count
    RETURN organization, patient, count, \"' 
    + event.request_id + 
    '\" AS request_id' 
    AS batch_producer,
    'WITH organization, patient, count, request_id
        CREATE (record:CityOrgPatientVisit)
            SET record.request_id = request_id,
                record.organization_city = organization.city,
                record.organization_name = organization.name,
                record.patient_id = patient.patient_id,
                record.encounter_count = count,
                record.timestamp = apoc.date.currentTimestamp()'
    AS batch_runner
WITH batch_producer, batch_runner
    CALL apoc.periodic.iterate(batch_producer, batch_runner, {batchSize:10000, parallel:true})
        YIELD total RETURN total
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
MATCH (record:CityOrgPatientVisit)
    WHERE record.timestamp > $lastCheck
RETURN
    record.request_id AS request_id,
    record.organization_city AS organization_city,
    record.organization_name AS organization_name,
    record.patient_id AS patient_id,
    record.encounter_count AS encounter_count,
    record.timestamp AS timestamp;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////