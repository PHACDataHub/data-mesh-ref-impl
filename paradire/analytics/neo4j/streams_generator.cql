/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating Vaccination Records
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
CALL apoc.periodic.iterate('
	MATCH (immunization:Immunization)
	WITH immunization ORDER BY immunization.date ASC
	RETURN immunization
','
	WITH immunization
    	MATCH (organization:Organization)-[]-(encounter:Encounter)-[:IMMUNIZATION_OF_ENCOUNTER]-(immunization)-[:IMMUNIZATION_OF_PATIENT]-(patient:Patient)
	WITH immunization, organization, encounter, patient
		CREATE (record:VaccinationRecord)
    		SET
    			record.immunization_date = immunization.date,
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
				record.timestamp = apoc.date.fromISO8601(TOSTRING(immunization.date))
',
	{batchSize:10000, parallel:true}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
