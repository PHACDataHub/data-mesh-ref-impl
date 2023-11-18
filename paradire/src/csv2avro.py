import avro.schema
from avro.datafile import DataFileWriter
from avro.io import DatumWriter
import multiprocessing
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
    'symptoms'
}


def convert_primitive(value, value_type):
    if value == '':
        if value_type == 'null':
            return 'null'
        if value_type  == 'string':
            return '""'
        assert False, f"Empty string cannot be converted into one of {type_list}."

    if value_type in ['int', 'long'] and all(e in '-0123456789' for e in value) and isinstance(int(value), int):
        return int(value)

    if value_type == 'float' and value == 'NaN':
        return 'null'
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

    if 'long' in type_list and all(e in '-0123456789' for e in value) and isinstance(int(value), int):
        return '{"long":' + f"{int(value)}" + '}'

    if 'float' in type_list and value == 'NaN':
        return 'null'
    if 'float' in type_list and isinstance(float(value), float):
        return '{"float":' + f"{float(value)}" + '}'

    if 'string' in type_list:
        return '{"string":"' + f"{value}" + '"}'
    
    assert False, f"{value} cannot be converted into one of {type_list}."


def process_file(arguments):
    entity, schema_folder, csv_folder, symptoms_folder, avro_folder = arguments
    key_schema = avro.schema.parse(open(f"{schema_folder}/{entity}_key.avsc", "rb").read())
    key_field_names = [field.name for field in key_schema.fields]
    val_schema = avro.schema.parse(open(f"{schema_folder}/{entity}_val.avsc", "rb").read())

    with open(f"{avro_folder}/{entity}.avro", "wt") as out_file:
        file_name = f"{csv_folder}/{entity}.csv" if entity != 'symptoms' else f"{symptoms_folder}/{entity}.csv"
        with open(file_name, "rt") as in_file:
            line_count = 1
            while True:
                line = in_file.readline()
                if entity == 'symptoms' and line_count == 1:
                    line = in_file.readline()
                if not line:
                    break
                line = line.strip()
                key_items = []
                val_items = []
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
                line_count += 1
    print(f"Processed {entity}")



def main():
    if len(sys.argv) < 5:
        print("""
              Usage: python csv2avro.py <schema_folder> <csv_folder> <symptoms_folder> <avro_folder>
              Example: python csv2avro.py governance/events ~/synthea/bc_spp/BC/csv/2023_11_08T15_35_59Z ~/synthea/bc_spp/BC/symptoms/csv/2023_11_08T15_36_00Z
        """)
        sys.exit(1)

    schema_folder = os.path.abspath(sys.argv[1])
    csv_folder = os.path.abspath(sys.argv[2])
    symptoms_folder = os.path.abspath(sys.argv[3])
    avro_folder = os.path.abspath(sys.argv[4])

    print(f"schema_folder {schema_folder}")
    print(f"csv_folder {csv_folder}")
    print(f"symptoms_folder {symptoms_folder}")
    print(f"avro_folder {avro_folder}")

    #The below function creates a multiprocessing pool with a number of processes 
    #equal to the lesser of the number of CSV files or the number of CPU cores. 
    #Each process will call the process_file function with the arguments for one CSV file. 
    #After all processes have been started, the pool.map call will wait for them to finish.
    tasks = [(entity, schema_folder, csv_folder, symptoms_folder, avro_folder) for entity in sorted(EHR_EVENTS)]

    # Determine the number of processes to spawn
    num_processes = min(len(tasks), multiprocessing.cpu_count())

    # Create a pool of processes and map the tasks to the processes
    with multiprocessing.Pool(processes=num_processes) as pool:
        pool.map(process_file, tasks)


if __name__ == '__main__':
    main()