/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Allergy entities
//
CREATE INDEX start_allergy FOR (n:Allergy) ON (n.start);
CREATE INDEX stop_allergy FOR (n:Allergy) ON (n.stop);
CREATE INDEX start_stop_allergy FOR (n:Allergy) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a ALLERGY_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a ALLERGY_OF_ENCOUNTER relation

CREATE TEXT INDEX code_allergy FOR (n:Allergy) ON (n.code);
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
// Creating constraints and indexes for Careplan entities
//
CREATE CONSTRAINT careplan_id IF NOT EXISTS FOR (n:Careplan) REQUIRE n.careplan_id IS UNIQUE;

CREATE INDEX start_careplan FOR (n:Careplan) ON (n.start);
CREATE INDEX stop_careplan FOR (n:Careplan) ON (n.stop);
CREATE INDEX start_stop_careplan FOR (n:Careplan) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a CAREPLAN_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a CAREPLAN_OF_ENCOUNTER relation

CREATE TEXT INDEX code_careplan FOR (n:Careplan) ON (n.code);
CREATE FULLTEXT INDEX description_careplan FOR (n:Careplan) ON (n.description);
CREATE TEXT INDEX reason_code_careplan FOR (n:Careplan) ON (n.reason_code);
CREATE FULLTEXT INDEX reason_description_careplan FOR (n:Careplan) ON (n.reason_description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Claim entities
//
CREATE CONSTRAINT claim_id IF NOT EXISTS FOR (n:Claim) REQUIRE n.claim_id IS UNIQUE;

// patient_id is used for identifying Patient entity, then establishing a CAREPLAN_OF_PATIENT relation
// provider_id is used for identifying Provider entity, then establishing a CAREPLAN_OF_PROVIDER relation
// primary_patient_insurance_id is used for identifying Payer entity, then establishing a CAREPLAN_OF_PRIMARY_PAYER relation
// secondary_patient_insurance_id is used for identifying Payer entity, then establishing a CAREPLAN_OF_SECONDARY_PAYER relation

CREATE INDEX department_id_claim FOR (n:Claim) ON (n.department_id);
CREATE INDEX patient_department_id_claim FOR (n:Claim) ON (n.patient_department_id);

CREATE TEXT INDEX diagnosis_1_claim FOR (n:Claim) ON (n.diagnosis_1_claim);
CREATE TEXT INDEX diagnosis_2_claim FOR (n:Claim) ON (n.diagnosis_2_claim);
CREATE TEXT INDEX diagnosis_3_claim FOR (n:Claim) ON (n.diagnosis_3_claim);

// appointment_id is used for identifying Encounter entity, then establishing a CAREPLAN_OF_ENCOUNTER relation

CREATE INDEX current_illness_date_claim FOR (n:Claim) ON (n.current_illness_date);
CREATE INDEX service_date_claim FOR (n:Claim) ON (n.service_date);

// supervising_provider_id is used for identifying supervising Provider entity, then establishing a CAREPLAN_OF_SUPERVISING_PROVIDER relation

CREATE INDEX status_1_claim FOR (n:Claim) ON (n.status_1);
CREATE INDEX status_2_claim FOR (n:Claim) ON (n.status_2);
CREATE INDEX status_p_claim FOR (n:Claim) ON (n.status_p);

CREATE INDEX healthcare_claim_type_id_1_claim FOR (n:Claim) ON (n.healthcare_claim_type_id_1);
CREATE INDEX healthcare_claim_type_id_2_claim FOR (n:Claim) ON (n.healthcare_claim_type_id_2);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Claim Transaction entities
//
CREATE CONSTRAINT claim_transaction_id IF NOT EXISTS FOR (n:ClaimTransaction) REQUIRE n.claim_transaction_id IS UNIQUE;

// claim_id is used for identifying Claim entity, then establishing a CLAIM_TRANSACTION_OF_CLAIM relation

CREATE INDEX charge_id_claim_transaction FOR (n:ClaimTransaction) ON (n.charge_id);

// patient_id is used for identifying Patient entity, then establishing a CLAIM_TRANSACTION_OF_PATIENT relation

CREATE INDEX claim_transaction_type_claim_transaction FOR (n:ClaimTransaction) ON (n.claim_transaction_type);
CREATE INDEX amount_claim_transaction FOR (n:ClaimTransaction) ON (n.amount);
CREATE INDEX method_claim_transaction FOR (n:ClaimTransaction) ON (n.method);

CREATE INDEX from_date_claim_transaction FOR (n:ClaimTransaction) ON (n.from_date);
CREATE INDEX to_date_claim_transaction FOR (n:ClaimTransaction) ON (n.to_date);
CREATE INDEX from_date_to_date_claim_transaction FOR (n:ClaimTransaction) ON (n.from_date, n.to_date);

// place_of_service is used for identifying Organization entity, then establishing a CLAIM_TRANSACTION_OF_ORGANIZATION relation

CREATE TEXT INDEX procedure_code_claim_transaction FOR (n:ClaimTransaction) ON (n.procedure_code);
CREATE INDEX department_id_claim_transaction FOR (n:ClaimTransaction) ON (n.department_id);
CREATE FULLTEXT INDEX notes_claim_transaction FOR (n:ClaimTransaction) ON (n.notes);
CREATE INDEX unit_amount_claim_transaction FOR (n:ClaimTransaction) ON (n.unit_amount);

// appointment_id is used for identifying Encounter entity, then establishing a CLAIM_TRANSACTION_OF_ENCOUNTER relation
// patient_insurance_id is used for identifying Payer Transition entity, then establishing a CLAIM_TRANSACTION_OF_PAYER_TRANSITION relation
// provider_id is used for identifying Provider entity, then establishing a CLAIM_TRANSACTION_OF_PROVIDER relation
// supervising_provider_id is used for identifying supervising Provider entity, then establishing a CLAIM_TRANSACTION_OF_SUPERVISING_PROVIDER relation
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Condition entities
//
CREATE INDEX start_condition FOR (n:Condition) ON (n.start);
CREATE INDEX stop_condition FOR (n:Condition) ON (n.stop);
CREATE INDEX start_stop_condition FOR (n:Condition) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a CONDITION_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a CONDITION_OF_ENCOUNTER relation

CREATE TEXT INDEX code_condition FOR (n:Condition) ON (n.code);
CREATE FULLTEXT INDEX description_condition FOR (n:Condition) ON (n.description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Device entities
//
CREATE INDEX start_device FOR (n:Device) ON (n.start);
CREATE INDEX stop_device FOR (n:Device) ON (n.stop);
CREATE INDEX start_stop_device FOR (n:Device) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a DEVICE_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a DEVICE_OF_ENCOUNTER relation

CREATE TEXT INDEX code_device FOR (n:Device) ON (n.code);
CREATE FULLTEXT INDEX description_device FOR (n:Device) ON (n.description);
CREATE FULLTEXT INDEX device_udi_device FOR (n:Device) ON (n.device_udi);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Encounter entities
//
CREATE CONSTRAINT encounter_id IF NOT EXISTS FOR (n:Encounter) REQUIRE n.encounter_id IS UNIQUE;

CREATE INDEX start_encounter FOR (n:Encounter) ON (n.start);
CREATE INDEX stop_encounter FOR (n:Encounter) ON (n.stop);
CREATE INDEX start_stop_encounter FOR (n:Encounter) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a ENCOUNTER_OF_PATIENT relation
// organization_id is used for identifying Payer entity, then establishing a ENCOUNTER_OF_ORGANIZATION relation
// provider_id is used for identifying Provider entity, then establishing a ENCOUNTER_OF_PROVIDER relation
// payer_id is used for identifying Encounter entity, then establishing a ENCOUNTER_OF_PAYER relation

CREATE INDEX encounter_class_encounter FOR (n:Encounter) ON (n.encounter_class);
CREATE TEXT INDEX code_encounter FOR (n:Encounter) ON (n.code);
CREATE FULLTEXT INDEX description_encounter FOR (n:Encounter) ON (n.description);

CREATE INDEX base_encounter_cost_encounter FOR (n:Encounter) ON (n.base_encounter_cost);
CREATE INDEX total_claim_cost_encounter FOR (n:Encounter) ON (n.total_claim_cost);
CREATE INDEX payer_coverage_encounter FOR (n:Encounter) ON (n.payer_coverage);

CREATE TEXT INDEX reason_code_encounter FOR (n:Encounter) ON (n.reason_code);
CREATE FULLTEXT INDEX reason_description_encounter FOR (n:Encounter) ON (n.reason_description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Imaging Study entities
//
CREATE CONSTRAINT imaging_study_id IF NOT EXISTS FOR (n:ImagingStudy) REQUIRE n.imaging_study_id IS UNIQUE;

CREATE INDEX date_imaging_study FOR (n:ImagingStudy) ON (n.date);

// patient_id is used for identifying Patient entity, then establishing a IMAGING_STUDY_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a IMAGING_STUDY_OF_ENCOUNTER relation

CREATE INDEX series_uid_imaging_study FOR (n:ImagingStudy) ON (n.series_uid);
CREATE TEXT INDEX body_site_code_imaging_study FOR (n:ImagingStudy) ON (n.body_site_code);
CREATE FULLTEXT INDEX body_site_description_imaging_study FOR (n:ImagingStudy) ON (n.body_site_description);
CREATE INDEX modality_code_imaging_study FOR (n:ImagingStudy) ON (n.modality_code);
CREATE FULLTEXT INDEX modality_description_imaging_study FOR (n:ImagingStudy) ON (n.modality_description);

CREATE INDEX instance_uid_imaging_study FOR (n:ImagingStudy) ON (n.instance_uid);
CREATE TEXT INDEX sop_code_imaging_study FOR (n:ImagingStudy) ON (n.sop_code);
CREATE FULLTEXT INDEX sop_description_imaging_study FOR (n:ImagingStudy) ON (n.sop_description);

CREATE TEXT INDEX procedure_code_imaging_study FOR (n:ImagingStudy) ON (n.procedure_code);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Immunization entities
//
// patient_id is used for identifying Patient entity, then establishing a IMMUNIZATION_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a IMMUNIZATION_OF_ENCOUNTER relation

CREATE TEXT INDEX code_immunization FOR (n:Immunization) ON (n.code);
CREATE FULLTEXT INDEX description_immunization FOR (n:Immunization) ON (n.description);
CREATE INDEX base_cost_immunization FOR (n:Immunization) ON (n.base_cost);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Medication entities
//
CREATE INDEX start_medication FOR (n:Medication) ON (n.start);
CREATE INDEX stop_medication FOR (n:Medication) ON (n.stop);
CREATE INDEX start_stop_medication FOR (n:Medication) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a MEDICATION_OF_PATIENT relation
// payer_id is used for identifying Payer entity, then establishing a MEDICATION_OF_PAYER relation
// encounter_id is used for identifying Encounter entity, then establishing a MEDICATION_OF_ENCOUNTER relation

CREATE TEXT INDEX code_medication FOR (n:Medication) ON (n.code);
CREATE FULLTEXT INDEX description_medication FOR (n:Medication) ON (n.description);

CREATE INDEX base_cost_medication FOR (n:Medication) ON (n.base_cost);
CREATE INDEX payer_coverage_medication FOR (n:Medication) ON (n.payer_coverage);
CREATE INDEX dispenses_medication FOR (n:Medication) ON (n.dispenses);
CREATE INDEX total_cost_medication FOR (n:Medication) ON (n.total_cost);

CREATE TEXT INDEX reason_code_medication FOR (n:Medication) ON (n.reason_code);
CREATE FULLTEXT INDEX reason_description_medication FOR (n:Medication) ON (n.reason_description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Observation entities
//
CREATE INDEX date_observation FOR (n:Observation) ON (n.date);

// patient_id is used for identifying Patient entity, then establishing a OBSERVATION_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a OBSERVATION_OF_ENCOUNTER relation

CREATE INDEX category_observation FOR (n:Observation) ON (n.category);
CREATE TEXT INDEX code_observation FOR (n:Observation) ON (n.code);
CREATE FULLTEXT INDEX description_observation FOR (n:Observation) ON (n.description);

CREATE INDEX value_observation FOR (n:Observation) ON (n.value);
CREATE INDEX units_observation FOR (n:Observation) ON (n.units);
CREATE INDEX observation_type_observation FOR (n:Observation) ON (n.observation_type);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Organization entities
//
CREATE CONSTRAINT organization_id IF NOT EXISTS FOR (n:Organization) REQUIRE n.organization_id IS UNIQUE;

CREATE TEXT INDEX name_organization FOR (n:Organization) ON (n.name);
CREATE FULLTEXT INDEX address_organization FOR (n:Organization) ON (n.address);
CREATE TEXT INDEX city_organization FOR (n:Organization) ON (n.city);
CREATE TEXT INDEX state_organization FOR (n:Organization) ON (n.state);
CREATE TEXT INDEX zip_organization FOR (n:Organization) ON (n.zip);

// Note that the location property is created from the lat and lon properties.
CREATE POINT INDEX location_organization FOR (n:Organization) ON (n.location);

CREATE TEXT INDEX phone_organization FOR (n:Organization) ON (n.phone);
CREATE INDEX revenue_organization FOR (n:Organization) ON (n.revenue);
CREATE INDEX utilization_organization FOR (n:Organization) ON (n.utilization);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Patient entities
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
CREATE TEXT INDEX county_patient FOR (n:Patient) ON (n.county);
CREATE TEXT INDEX zip_patient FOR (n:Patient) ON (n.zip);

// Note that the location property is created from the lat and lon properties.
CREATE POINT INDEX location_patient FOR (n:Patient) ON (n.location);

CREATE INDEX healthcare_expenses_patient FOR (n:Patient) ON (n.healthcare_expenses);
CREATE INDEX healthcare_coverage_patient FOR (n:Patient) ON (n.healthcare_coverage);
CREATE INDEX income_patient FOR (n:Patient) ON (n.income);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Payer Transition entities
//
// patient_id is used for identifying Patient entity, then establishing a PAYER_TRANSITION_OF_PATIENT relation

CREATE INDEX member_id_payer_transition FOR (n:PayerTransition) ON (n.member_id);

CREATE INDEX start_year_encounter FOR (n:PayerTransition) ON (n.start_year);
CREATE INDEX end_year_encounter FOR (n:PayerTransition) ON (n.end_year);
CREATE INDEX start_year_end_year_encounter FOR (n:PayerTransition) ON (n.start_year, n.end_year);

// payer_id is used for identifying Payer entity, then establishing a PAYER_TRANSITION_OF_PAYER relation
// secondary_payer_id is used for identifying secondary Payer entity, then establishing a PAYER_TRANSITION_OF_SECONDARY_PAYER relation

CREATE INDEX plan_ownership_payer_transition FOR (n:PayerTransition) ON (n.plan_ownership);
CREATE FULLTEXT INDEX owner_name_payer_transition FOR (n:PayerTransition) ON (n.owner_name);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Payer entities
//
CREATE CONSTRAINT payer_id IF NOT EXISTS FOR (n:Payer) REQUIRE n.payer_id IS UNIQUE;

CREATE TEXT INDEX name_payer FOR (n:Payer) ON (n.name);
CREATE FULLTEXT INDEX address_payer FOR (n:Payer) ON (n.address);
CREATE TEXT INDEX city_payer FOR (n:Payer) ON (n.city);
CREATE TEXT INDEX state_headquartered_payer FOR (n:Payer) ON (n.state_headquartered);
CREATE TEXT INDEX zip_payer FOR (n:Payer) ON (n.zip);
CREATE TEXT INDEX phone_payer FOR (n:Payer) ON (n.phone);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Procedure entities
//
CREATE INDEX start_procedurer FOR (n:Procedure) ON (n.start);
CREATE INDEX stop_procedure FOR (n:Procedure) ON (n.stop);
CREATE INDEX start_stop_procedure FOR (n:Procedure) ON (n.start, n.stop);

// patient_id is used for identifying Patient entity, then establishing a PROCEDURE_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a PROCEDURE_OF_ENCOUNTER relation

CREATE TEXT INDEX code_procedure FOR (n:Procedure) ON (n.code);
CREATE FULLTEXT INDEX description_procedure FOR (n:Procedure) ON (n.description);

CREATE INDEX base_cost_procedure FOR (n:Procedure) ON (n.base_cost);
CREATE INDEX reason_code_procedure FOR (n:Procedure) ON (n.reason_code);
CREATE INDEX reason_description_procedure FOR (n:Procedure) ON (n.reason_description);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Provider entities
//
CREATE CONSTRAINT provider_id IF NOT EXISTS FOR (n:Provider) REQUIRE n.provider_id IS UNIQUE;

// organization_id is used for identifying Provider entity, then establishing a PROVIDER_OF_ORGANIZATION relation

CREATE TEXT INDEX name_provider FOR (n:Provider) ON (n.name);
CREATE INDEX gender_provider FOR (n:Provider) ON (n.gender);
CREATE INDEX speciality_provider FOR (n:Provider) ON (n.speciality);
CREATE FULLTEXT INDEX address_provider FOR (n:Provider) ON (n.address);
CREATE TEXT INDEX city_provider FOR (n:Provider) ON (n.city);
CREATE TEXT INDEX state_provider FOR (n:Provider) ON (n.state);
CREATE TEXT INDEX zip_provider FOR (n:Provider) ON (n.zip);

// Note that the location property is created from the lat and lon properties.
CREATE POINT INDEX location_provider FOR (n:Provider) ON (n.location);

CREATE INDEX encounters_cost_provider FOR (n:Provider) ON (n.encounters);
CREATE INDEX procedures_code_provider FOR (n:Provider) ON (n.procedures);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints and indexes for Supply entities
//
CREATE CONSTRAINT supply_id IF NOT EXISTS FOR (n:Supply) REQUIRE n.supply_id IS UNIQUE;

CREATE INDEX date_supply FOR (n:Supply) ON (n.date);

// patient_id is used for identifying Patient entity, then establishing a SUPPLY_OF_PATIENT relation
// encounter_id is used for identifying Encounter entity, then establishing a SUPPLY_OF_ENCOUNTER relation

CREATE TEXT INDEX code_supply FOR (n:Supply) ON (n.code);
CREATE FULLTEXT INDEX description_supply FOR (n:Supply) ON (n.description);
CREATE INDEX quantity_code_supply FOR (n:Supply) ON (n.quantity);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
