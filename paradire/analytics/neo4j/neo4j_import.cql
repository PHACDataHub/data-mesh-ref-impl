/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Patients
//
CREATE CONSTRAINT patient_id IF NOT EXISTS FOR (n:Patient) REQUIRE n.patient_id IS UNIQUE;

CREATE INDEX birth_date_patient FOR (n:Patient) ON (n.birth_date);
CREATE TEXT INDEX ssn_patient FOR (n:Patient) ON (n.ssn);
CREATE TEXT INDEX drivers_patient FOR (n:Patient) ON (n.drivers);
CREATE TEXT INDEX passport_patient FOR (n:Patient) ON (n.passport);

CREATE TEXT INDEX marital_patient FOR (n:Patient) ON (n.marital);
CREATE TEXT INDEX race_patient FOR (n:Patient) ON (n.race);
CREATE TEXT INDEX ethnicity_patient FOR (n:Patient) ON (n.ethnicity);
CREATE TEXT INDEX gender_patient FOR (n:Patient) ON (n.gender);

CREATE FULLTEXT INDEX address_patient FOR (n:Patient) ON (n.address);
CREATE TEXT INDEX city_patient FOR (n:Patient) ON (n.city);
CREATE TEXT INDEX state_patient FOR (n:Patient) ON (n.state);
CREATE TEXT INDEX string_patient FOR (n:Patient) ON (n.string);
CREATE TEXT INDEX zip_patient FOR (n:Patient) ON (n.zip);

CREATE INDEX healthcare_expenses_patient FOR (n:Patient) ON (n.healthcare_expenses);
CREATE INDEX healthcare_coverage_patient FOR (n:Patient) ON (n.healthcare_coverage);
CREATE INDEX income_patient FOR (n:Patient) ON (n.income);

CREATE POINT INDEX location_patient FOR (n:Patient) ON (n.location);
//
// Note that the location property is created from the lat and lon properties.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Allergies
//
CREATE INDEX start_allergy FOR (n:Allergy) ON (n.start);
CREATE INDEX stop_allergy FOR (n:Allergy) ON (n.stop);
CREATE INDEX start_stop_allergy FOR (n:Allergy) ON (n.start, n.stop);

CREATE INDEX patient_id_allergy FOR (n:Allergy) ON (n.patient_id);
CREATE INDEX encounter_id_allergy FOR (n:Allergy) ON (n.encounter_id);
CREATE INDEX patient_id_encounter_id_allergy FOR (n:Allergy) ON (n.patient_id, n.encounter_id);

CREATE INDEX code_allergy FOR (n:Allergy) ON (n.code);
CREATE INDEX system_allergy FOR (n:Allergy) ON (n.system);
CREATE FULLTEXT INDEX description_allergy FOR (n:Allergy) ON (n.description);
CREATE INDEX allergy_type_allergy FOR (n:Allergy) ON (n.allergy_type);
CREATE INDEX category_allergy FOR (n:Allergy) ON (n.category);

CREATE INDEX reaction_1_allergy FOR (n:Allergy) ON (n.reaction_1);
CREATE FULLTEXT INDEX description_1_allergy FOR (n:Allergy) ON (n.description_1);
CREATE INDEX severity_1_allergy FOR (n:Allergy) ON (n.severity_1);
CREATE INDEX reaction_2_allergy FOR (n:Allergy) ON (n.reaction_2);
CREATE FULLTEXT INDEX description_2_allergy FOR (n:Allergy) ON (n.description_2);
CREATE INDEX severity_2_allergy FOR (n:Allergy) ON (n.severity_2);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Careplans
//
CREATE CONSTRAINT careplan_id IF NOT EXISTS FOR (n:Careplan) REQUIRE n.careplan_id IS UNIQUE;

CREATE INDEX start_careplan FOR (n:Careplan) ON (n.start);
CREATE INDEX stop_careplan FOR (n:Careplan) ON (n.stop);
CREATE INDEX start_stop_careplan FOR (n:Careplan) ON (n.start, n.stop);

CREATE INDEX patient_id_careplan FOR (n:Careplan) ON (n.patient_id);
CREATE INDEX encounter_id_careplan FOR (n:Careplan) ON (n.encounter_id);
CREATE INDEX patient_id_encounter_id_careplan FOR (n:Careplan) ON (n.patient_id, n.encounter_id);

CREATE INDEX code_careplan FOR (n:Careplan) ON (n.code);
CREATE FULLTEXT INDEX description_careplan FOR (n:Careplan) ON (n.description);
CREATE INDEX reason_code_careplan FOR (n:Careplan) ON (n.reason_code);
CREATE FULLTEXT INDEX reason_description_careplan FOR (n:Careplan) ON (n.reason_description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
