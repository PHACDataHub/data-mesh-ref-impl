pt=$1

./cleanup_f_cluster.sh
git checkout .
git checkout main
./setup_pt_cluster.sh $pt 35.203.40.154

source .env

./start_pt_cluster.sh
./v2_setup_analytics_pipeline.sh
./v2_pt_setup_ehr_event_streams.sh
./v2_pt_setup_fed_request_connectors.sh 

sed -i "s/http:\/\/localhost:8080\/fhir/https:\/\/$PUBLIC_IP\/fhir/" hapi_fhir_patch/hapi.application.yaml

./setup_pt_fhir.sh 
docker compose -f docker-compose-pt-acg-governance.yml up --build -d
apt-get install python3-venv
./convert_ehr_to_avro.sh /home/luc_belliveau_gcp_hc_sc_gc_ca/synthea/ca_spp/ab/csv/2023_11_21T18_01_41Z/ /home/luc_belliveau_gcp_hc_sc_gc_ca/synthea/ca_spp/ab/symptoms/csv/2023_11_21T18_01_42Z/ data 
./stream_pt_ehr_events.sh data

sed -i "s/http:\/\/localhost:8080\/fhir/https:\/\/$PUBLIC_IP\/fhir/" patient_browser_patch/default.json5
./setup_patient_browser.sh

