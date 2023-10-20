import avro.constants
import avro.schema
from avro.datafile import DataFileWriter
from avro.io import DatumWriter

import os
import sys


EHR_EVENTS = {
    'allergies', # 'start,stop,patient_id,encounter_id,code,system,description,type,category,reaction_1,description_1,severity_1,reaction_2,description_2,severity_2',
    'careplans', # 'careplan_id,start,stop,patient_id,encounter_id,code,description,reason_code,reason_description',
    'claims', # 'claim_id,patient_id,provider_id,primary_patient_insurance_id,secondary_patient_insurance_id,department_id,patient_department_id,diagnosis_1,diagnosis_2,diagnosis_3,diagnosis_4,diagnosis_5,diagnosis_6,diagnosis_7,diagnosis_8,referring_provider_id,appointment_id,current_illness_date,service_date,supervising_provider_id,status_1,status_2,status_p,outstanding_1,outstanding_2,outstanding_p,last_billed_date_1,last_billed_date_2,last_billed_date_p,healthcare_claim_type_id_1,healthcare_claim_type_id_2',
    'claims_transactions', # 'claim_transaction_id,claim_id,charge_id,patient_id,type,amount,method,from_date,to_date,place_of_service,procedure_code,modifier_1,modifier_2,diagnosis_ref_1,diagnosis_ref_2,diagnosis_ref_3,diagnosis_ref_4,units,department_id,notes,unit_amount,transfer_out_id,transfer_type,payments,adjustments,transfers,outstanding,appointment_id,line_note,patient_insurance_id,fee_schedule_id,provider_id,supervising_provider_id',
    'conditions', # 'start,stop,patient_id,encounter_id,code,description',
    'devices', # 'start,stop,patient_id,encounter_id,code,description,device_udi',
    'encounters', # 'encounter_id,start,stop,patient_id,organization_id,provider_id,payer_id,encounter_class,code,description,base_encounter_cost,total_claim_cost,payer_coverage,reason_code,reason_description',
    'imaging_studies', # 'imaging_study_id,date,patient_id,encounter_id,series_uid,body_site_code,body_site_description,modality_code,modality_description,instance_uid,sop_code,sop_description,procedure_code',
    'immunizations', # 'date,patient_id,encounter_id,code,description,base_cost',
    'medications', # 'start,stop,patient_id,payer_id,encounter_id,code,description,base_cost,payer_coverage,dispenses,total_cost,reason_code,reason_description',
    'observations', # 'date,patient_id,encounter_id,category,code,description,value,units,type',
    'organizations', # 'organization_id,name,address,city,state,zip,lat,lon,phone,revenue,utilization',
    'patient_expenses', # 'patient_id,year,payer_id,healthcare_expenses,insurance_costs,covered_costs',
    'patients', # 'patient_id,birth_date,death_date,ssn,drivers,passport,prefix,first,last,suffix,maiden,marital,race,ethnicity,gender,birth_place,address,city,state,county,fips,zip,lat,lon,healthcare_expenses,healthcare_coverage,income',
    'payer_transitions', # 'patient_id,member_id,start_year,end_year,payer_id,secondary_payer_id,plan_ownership,owner_name',
    'payers', # 'payer_id,name,ownership,address,city,state_headquartered,zip,phone,amount_covered,amount_uncovered,revenue,covered_encounters,uncovered_encounters,covered_medications,uncovered_medications,covered_procedures,uncovered_procedures,covered_immunizations,uncovered_immunizations,unique_customers,qols_avg,member_months',
    'procedures', # 'start,stop,patient_id,encounter_id,code,description,base_cost,reason_code,reason_description',
    'providers', # 'provider_id,organization_id,name,gender,speciality,address,city,state,zip,lat,lon,encounters,procedures',
    'supplies', # 'date,patient_id,encounter_id,code,description,quantity'
}


def convert_primitive(value, value_type):
    if value == '':
        if value_type == 'null':
            return 'null'
        if value_type  == 'string':
            return ''
        assert False, f"Empty string cannot be converted into one of {type_list}."

    if value_type == 'int' and all(e in '-0123456789' for e in value) and isinstance(int(value), int):
        return int(value)

    if value_type == 'float' and isinstance(float(value), float):
        return float(value)

    if value_type == 'string':
        return '"' + f"{value}" + '"'
    
    assert False, f"{value} cannot be converted into one of {type_list}."


def convert_union(value, type_list):
    if value == '':
        if 'null' in type_list:
            return 'null'
        if 'string' in type_list:
            return '{"string": ""}'
        assert False, f"Empty string cannot be converted into one of {type_list}."

    if 'int' in type_list and all(e in '-0123456789' for e in value) and isinstance(int(value), int):
        return '{"int":' + f"{int(value)}" + '}'

    if 'float' in type_list and isinstance(float(value), float):
        return '{"float":' + f"{float(value)}" + '}'

    if 'string' in type_list:
        return '{"string":"' + f"{value}" + '"}'
    
    assert False, f"{value} cannot be converted into one of {type_list}."


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("""
              Usage: python csv2avro.py <csv_folder>
              Example: ~/synthea/ca_spp/SK/avro/2023_10_17T22_19_30Z
        """)
        exit(1)
    
    schema_path = os.path.abspath(sys.argv[1])
    input_path = os.path.abspath(sys.argv[2])
    output_path = os.path.abspath(sys.argv[3])
    if not os.path.isdir(output_path):
        os.mkdir(output_path)
    
    for entity in sorted(EHR_EVENTS):
        print(entity)

        key_schema = avro.schema.parse(open(f"{schema_path}/{entity}_key.avsc", "rb").read())
        key_field_names = [field.name for field in key_schema.fields]
        val_schema = avro.schema.parse(open(f"{schema_path}/{entity}_val.avsc", "rb").read())
        
        with open(f"{output_path}/{entity}.avro", "wt") as out_file:
            with open(f"{input_path}/{entity}.csv") as in_file:
                
                line = in_file.readline()
                line_count = 1
                while True:
                    line = in_file.readline()
                    if not line:
                        break
                    
                    line  = line.strip()
                    key_items = []
                    val_items = []
                    print(f"[{entity}] [{line_count}] {line}")
                    for field, cell in zip(val_schema.fields, line.split(',')):
                        if isinstance(field.type, avro.schema.PrimitiveSchema):
                            item = f"\"{field.name}\": {convert_primitive(cell, field.type.fullname)}"
                            val_items.append(item)
                            if field.name in key_field_names:
                                key_items.append(item)
                        elif isinstance(field.type, avro.schema.UnionSchema):
                            val_items.append(f"\"{field.name}\": {convert_union(cell, [schema.type for schema in field.type.schemas])}")
                        else:
                            assert False, f"Unknown field type {field.type.__class__.__name__}"
                    
                    key = '{' + ', '.join(key_items) + '}'
                    val = '{' + ', '.join(val_items) + '}'
                    out_file.write(f"{key}|{val}\n")
                    
                    line_count +=1
