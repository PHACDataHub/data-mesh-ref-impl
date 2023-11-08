CREATE (n:Allergy) 
    SET n.start = DATE(event.start), 
        n.stop = DATE(event.stop), 
        n.code = event.code, 
        n.system = event.system,
        n.description = event.description,
        n.allergy_type = event.allergy_type,
        n.category = event.category,
        n.reaction_1 = event.reaction_1,
        n.description_1 = event.description_1,
        n.severity_1 = event.severity_1,
        n.reaction_2 = event.reaction_2,
        n.description_2 = event.description_2,
        n.severity_2 = event.severity_2
WITH n, event 
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:ALLERGY_OF_PATIENT]->(patient)
    MERGE (n)-[:ALLERGY_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Careplan {careplan_id: event.careplan_id})
    SET n.start = DATE(event.start), 
        n.stop = DATE(event.stop),
        n.code = event.code,
        n.description = event.description,
        n.reason_code = event.reason_code,
        n.reason_description = event.reason_description
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:CAREPLAN_OF_PATIENT]->(patient)
    MERGE (n)-[:CAREPLAN_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Claim {claim_id: event.claim_id})
    SET n.department_id = event.department_id,
        n.patient_department_id = event.patient_department_id,
        n.diagnosis_1 = event.diagnosis_1,
        n.diagnosis_2 = event.diagnosis_2,
        n.diagnosis_3 = event.diagnosis_3,
        n.diagnosis_4 = event.diagnosis_4,
        n.diagnosis_5 = event.diagnosis_5,
        n.diagnosis_6 = event.diagnosis_6,
        n.diagnosis_7 = event.diagnosis_7,
        n.diagnosis_8 = event.diagnosis_8,
        n.current_illness_date = DATETIME(event.current_illness_date),
        n.service_date = DATETIME(event.service_date),
        n.status_1 = event.status_1,
        n.status_2 = event.status_2,
        n.status_p = event.status_p,
        n.outstanding_1 = event.outstanding_1,
        n.outstanding_2 = event.outstanding_2,
        n.outstanding_p = event.outstanding_p,
        n.last_billed_date_1 = event.last_billed_date_1,
        n.last_billed_date_2 = event.last_billed_date_2,
        n.last_billed_date_p = event.last_billed_date_p,
        n.healthcare_claim_type_id_1 = event.healthcare_claim_type_id_1,
        n.healthcare_claim_type_id_2 = event.healthcare_claim_type_id_2
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (provider:Provider {provider_id: event.provider_id})
WITH n, event, patient, provider
    MERGE (n)-[:CLAIM_OF_PATIENT]->(patient)
    MERGE (n)-[:CLAIM_OF_PROVIDER]->(provider)
WITH n, event
    FOREACH (dummy IN CASE WHEN event.primary_patient_insurance_id IS NOT NULL THEN [1] ELSE [] END |
        MERGE (primary_payer:Payer {payer_id: event.primary_patient_insurance_id})
        MERGE (n)-[:CLAIM_OF_PRIMARY_PAYER]->(primary_payer)
    )
    FOREACH (dummy IN CASE WHEN event.secondary_patient_insurance_id IS NOT NULL THEN [1] ELSE [] END | 
        MERGE (secondary_payer:Payer {payer_id: event.secondary_patient_insurance_id})
        MERGE (n)-[:CLAIM_OF_SECONDARY_PAYER]->(secondary_payer)
    )
    FOREACH (dummy IN CASE WHEN event.referring_provider_id IS NOT NULL THEN [1] ELSE [] END |
        MERGE (referring_provider:Provider {provider_id: event.referring_provider_id})
        MERGE (n)-[:CLAIM_OF_REFERRING_PROVIDER]->(referring_provider)
    )
    FOREACH (dummy IN CASE WHEN event.appointment_id IS NOT NULL THEN [1] ELSE [] END | 
        MERGE (encounter:Encounter {encounter_id: event.appointment_id}) 
        MERGE (n)-[:CLAIM_OF_ENCOUNTER]->(encounter)
    )
    FOREACH (dummy IN CASE WHEN event.supervising_provider_id IS NOT NULL THEN [1] ELSE [] END | 
        MERGE (supervising_provider:Provider {provider_id: event.supervising_provider_id}) 
        MERGE (n)-[:CLAIM_OF_SUPERVISING_PROVIDER]->(supervising_provider)
    )
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:ClaimTransaction {claim_transaction_id: event.claim_transaction_id})
    SET n.charge_id = event.charge_id,
        n.claim_transaction_type = event.claim_transaction_type,
        n.amount = event.amount,
        n.method = event.method,
        n.from_date = DATETIME(event.from_date),
        n.to_date = DATETIME(event.to_date),
        n.procedure_code = event.procedure_code,
        n.modifier_1 = event.modifier_1,
        n.modifier_2 = event.modifier_2,
        n.diagnosis_ref_1 = event.diagnosis_ref_1,
        n.diagnosis_ref_2 = event.diagnosis_ref_2,
        n.diagnosis_ref_3 = event.diagnosis_ref_3,
        n.diagnosis_ref_4 = event.diagnosis_ref_4,
        n.units = event.units,
        n.department_id = event.department_id,
        n.notes = event.notes,
        n.unit_amount = event.unit_amount,
        n.transfer_out_id = event.transfer_out_id,
        n.transfer_type = event.transfer_type,
        n.payments = event.payments,
        n.adjustments = event.adjustments,
        n.transfers = event.transfers,
        n.outstanding = event.outstanding,
        n.line_note = event.line_note,
        n.patient_insurance_id = event.patient_insurance_id,
        n.fee_schedule_id = event.fee_schedule_id
WITH n, event
    MERGE (claim:Claim {claim_id: event.claim_id})
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (organization:Organization {organization_id: event.organization_id})
    MERGE (provider:Provider {provider_id: event.provider_id})
WITH n, event, claim, patient, organization, provider
    MERGE (n)-[:CLAIM_TRANSACTION_OF_CLAIM]->(claim)
    MERGE (n)-[:CLAIM_TRANSACTION_OF_PATIENT]->(patient)
    MERGE (n)-[:CLAIM_TRANSACTION_OF_ORGANIZATION]->(organization)
    MERGE (n)-[:CLAIM_TRANSACTION_OF_PROVIDER]->(provider) 
WITH n, event
    FOREACH (dummy IN CASE WHEN event.appointment_id IS NOT NULL THEN [1] ELSE [] END | 
        MERGE (encounter:Encounter {encounter_id: event.appointment_id})
        MERGE (n)-[:CLAIM_TRANSACTION_OF_ENCOUNTER]->(encounter)
    )
    FOREACH (dummy IN CASE WHEN event.supervising_provider_id IS NOT NULL THEN [1] ELSE [] END |
        MERGE (supervising_provider:Provider {provider_id: event.supervising_provider_id})
        MERGE (n)-[:CLAIM_TRANSACTION_OF_SUPERVISING_PROVIDER]->(supervising_provider)
    )
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Condition)
    SET n.start = DATE(event.start),
        n.stop = DATE(event.stop),
        n.code = event.code,
        n.description = event.description
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:CONDITION_OF_PATIENT]->(patient)
    MERGE (n)-[:CONDITION_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Device)
    SET n.start = DATETIME(event.start),
        n.stop = DATETIME(event.stop),
        n.code = event.code,
        n.description = event.description,
        n.device_udi = event.device_udi
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:DEVICE_OF_PATIENT]->(patient)
    MERGE (n)-[:DEVICE_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Encounter {encounter_id: event.encounter_id})
    SET n.start = DATETIME(event.start),
        n.stop = DATETIME(event.stop),
        n.encounter_class = event.encounter_class,
        n.code = event.code,
        n.description = event.description,
        n.base_encounter_cost = event.base_encounter_cost,
        n.total_claim_cost = event.total_claim_cost,
        n.payer_coverage = event.payer_coverage,
        n.reason_code = event.reason_code,
        n.reason_description = event.reason_description
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (organization:Organization {organization_id: event.organization_id})
    MERGE (provider:Provider {provider_id: event.provider_id})
    MERGE (payer:Payer {payer_id: event.payer_id})
WITH n, patient, organization, provider, payer
    MERGE (n)-[:ENCOUNTER_OF_PATIENT]->(patient)
    MERGE (n)-[:ENCOUNTER_OF_ORGANIZATION]->(organization)
    MERGE (n)-[:ENCOUNTER_OF_PROVIDER]->(provider)
    MERGE (n)-[:ENCOUNTER_OF_PAYER]->(payer)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:ImagingStudy)
    SET n.imaging_study_id = event.imaging_study_id,
        n.date = DATETIME(event.start),
        n.series_uid = event.series_uid,
        n.body_site_code = event.body_site_code,
        n.body_site_description = event.body_site_description,
        n.modality_code = event.modality_code,
        n.modality_description = event.modality_description,
        n.instance_uid = event.instance_uid,
        n.sop_code = event.sop_code,
        n.sop_description = event.sop_description,
        n.procedure_code = event.procedure_code
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:IMAGING_STUDY_OF_PATIENT]->(patient)
    MERGE (n)-[:IMAGING_STUDY_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Immunization)
    SET n.date = DATETIME(event.date),
        n.code = event.code,
        n.description = event.description,
        n.base_cost = event.base_cost
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:IMMUNIZATION_OF_PATIENT]->(patient)
    MERGE (n)-[:IMMUNIZATION_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Medication)
    SET n.start = DATETIME(event.start),
        n.stop = DATETIME(event.stop),
        n.code = event.code,
        n.description = event.description,
        n.base_cost = event.base_cost,
        n.payer_coverage = event.payer_coverage,
        n.dispenses = event.dispenses,
        n.total_cost = event.total_cost,
        n.reason_code = event.reason_code,
        n.reason_description = event.reason_description
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
    MERGE (payer:Payer {payer_id: event.payer_id})
WITH n, patient, encounter
    MERGE (n)-[:MEDICATION_OF_PATIENT]->(patient)
    MERGE (n)-[:MEDICATION_OF_ENCOUNTER]->(encounter)
    MERGE (n)-[:MEDICATION_OF_PAYER]->(payer)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Observation)
    SET n.date = DATETIME(event.date),
        n.category = event.category,
        n.code = event.code,
        n.description = event.description,
        n.value = event.value,
        n.units = event.units,
        n.observation_type = event.observation_type
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
WITH n, event, patient
    MERGE (n)-[:OBSERVATION_OF_PATIENT]->(patient)
WITH n, event
    FOREACH (dummy IN CASE WHEN event.encounter_id IS NOT NULL AND SIZE(event.encounter_id) > 0 THEN [1] ELSE [] END |
        MERGE (encounter:Encounter {encounter_id: event.encounter_id})
        MERGE (n)-[:OBSERVATION_OF_ENCOUNTER]->(encounter)
    )
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Organization {organization_id: event.organization_id})
    SET n.name = event.name,
        n.address = event.address,
        n.city = event.city,
        n.state = event.state,
        n.zip = event.zip,
        n.location = POINT({latitude: event.lat, longitude: event.lon}),
        n.phone = event.phone,
        n.revenue = event.revenue,
        n.utilization = event.utilization
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:PatientExpense)
    SET n.year = DATETIME(event.year),
        n.healthcare_expenses = event.healthcare_expenses,
        n.insurance_costs = event.insurance_costs,
        n.covered_costs = event.covered_costs
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (payer:Payer {payer_id: event.payer_id})
WITH n, patient, payer
    MERGE (n)-[:PATIENT_EXPENSE_OF_PATIENT]->(patient)
    MERGE (n)-[:PATIENT_EXPENSE_OF_PAYER]->(payer)
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Patient {patient_id: event.patient_id})
    SET n.birth_date = DATE(event.birth_date),
        n.death_date = DATE(event.death_date),
        n.ssn = event.ssn,
        n.drivers = event.drivers,
        n.passport = event.passport,
        n.prefix = event.prefix,
        n.first = event.first,
        n.last = event.last,
        n.suffix = event.suffix,
        n.maiden = event.maiden,
        n.marital = event.marital,
        n.race = event.race,
        n.ethnicity = event.ethnicity,
        n.gender = event.gender,
        n.birth_place = event.birth_place,
        n.address = event.address,
        n.city = event.city,
        n.county = event.county,
        n.fips = event.fips,
        n.zip = event.zip,
        n.location = POINT({latitude: event.lat, longitude: event.lon}),
        n.healthcare_expenses = event.healthcare_expenses,
        n.healthcare_coverage = event.healthcare_coverage,
        n.income = event.income
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:PayerTransition)
    SET n.member_id = event.member_id,
        n.start_year = DATETIME(event.start_year),
        n.end_year = DATETIME(event.end_year),
        n.plan_ownership = event.plan_ownership,
        n.owner_name = event.owner_name
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (payer:Payer {payer_id: event.payer_id})
WITH n, event, patient, payer
    MERGE (n)-[:PAYER_TRANSITION_OF_PATIENT]->(patient)
    MERGE (n)-[:PAYER_TRANSITION_OF_PAYER]->(payer)
WITH n, event
    FOREACH (dummy IN CASE WHEN event.secondary_payer_id IS NOT NULL THEN [1] ELSE [] END |
        MERGE (secondary_payer:Payer {payer_id: event.secondary_payer_id})
        MERGE (n)-[:PAYER_TRANSITION_OF_SECONDARY_PAYER]->(secondary_payer)
    )
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Payer {payer_id: event.payer_id})
    SET n.name = event.name,
        n.ownership = event.ownership,
        n.address = event.address,
        n.city = event.city,
        n.state_headquartered = event.state_headquartered,
        n.zip = event.zip,
        n.phone = event.phone,
        n.amount_covered = event.amount_covered,
        n.amount_uncovered = event.amount_uncovered,
        n.revenue = event.revenue,
        n.covered_encounters = event.covered_encounters,
        n.uncovered_encounters = event.uncovered_encounters,
        n.covered_medications = event.covered_medications,
        n.uncovered_medications = event.uncovered_medications,
        n.covered_procedures = event.covered_procedures,
        n.uncovered_procedures = event.uncovered_procedures,
        n.covered_immunizations = event.covered_immunizations,
        n.uncovered_immunizations = event.uncovered_immunizations,
        n.unique_customers = event.unique_customers,
        n.qols_avg = event.qols_avg,
        n.member_months = event.member_months
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Procedure)
    SET n.start = DATETIME(event.start),
        n.stop = DATETIME(event.stop),
        n.code = event.code,
        n.description = event.description,
        n.base_cost = event.base_cost,
        n.reason_code = event.reason_code,
        n.reason_description = event.reason_description
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:PROCEDURE_OF_PATIENT]->(patient)
    MERGE (n)-[:PROCEDURE_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
MERGE (n:Provider {provider_id: event.provider_id})
    SET n.name = event.name,
        n.gender = event.gender,
        n.speciality = event.speciality,
        n.address = event.address,
        n.city = event.city,
        n.state = event.state,
        n.zip = event.zip,
        n.location = POINT({latitude: event.lat, longitude: event.lon}),
        n.encounters = event.encounters,
        n.procedures = event.procedures
WITH n, event
    FOREACH (dummy IN CASE WHEN event.organization_id IS NOT NULL THEN [1] ELSE [] END |
        MERGE (organization:Organization {organization_id: event.organization_id})
        MERGE (n)-[:PROVIDER_OF_ORGANIZATION]->(organization)
    )
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Supply)
    SET n.date = DATETIME(event.date),
        n.code = event.code,
        n.description = event.description,
        n.quantity = event.quantity
WITH n, event
    MERGE (patient:Patient {patient_id: event.patient_id})
    MERGE (encounter:Encounter {encounter_id: event.encounter_id})
WITH n, patient, encounter
    MERGE (n)-[:PROCEDURE_OF_PATIENT]->(patient)
    MERGE (n)-[:PROCEDURE_OF_ENCOUNTER]->(encounter)
////////////////////////////////////////////////////////////////////////////////////////////////////
CREATE (n:Symptom {patient_id: event.patient_id})
    SET n.race = event.race,
        n.ethnicity = event.ethnicity,
        n.gender = event.gender,
        n.age_begin = event.age_begin,
        n.age_end = event.age_end,
        n.pathology = event.pathology,
        n.num_symptoms = event.num_symptoms,
        n.symptoms = event.symptoms
////////////////////////////////////////////////////////////////////////////////////////////////////