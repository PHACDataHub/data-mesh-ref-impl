./cleanup_pt_cluster.sh
docker compose -f docker-compose-pt-acg-governance.yml down -v
docker rm -f patient-browser
git checkout .
git pull

./setup_pt_cluster.sh $PT $phac

source .env

./start_pt_cluster.sh
./v2_setup_analytics_pipeline.sh
./v2_pt_setup_ehr_event_streams.sh
./v2_pt_setup_fed_request_connectors.sh 

sed -i "s/http:\/\/localhost:8080\/fhir/http:\/\/$PUBLIC_IP:8080\/fhir/" hapi_fhir_patch/hapi.application.yaml

./setup_pt_fhir.sh 

sudo apt-get install python3-venv python3-avro -y
rm -rf /home/luc_belliveau_gcp_hc_sc_gc_ca/Immunization_Gateway_ENV/
./generate_patient_population.sh 1000 ca_spp $PT

./convert_ehr_to_avro.sh $(realpath /home/luc_belliveau_gcp_hc_sc_gc_ca/synthea/ca_spp/${pt,,}/csv/*/) $(realpath /home/luc_belliveau_gcp_hc_sc_gc_ca/synthea/ca_spp/${pt,,}/symptoms/csv/*/) data 
./stream_pt_ehr_events.sh data

docker compose -f docker-compose-pt-acg-governance.yml up --build -d

sed -i "s/http:\/\/localhost:8080\/fhir/http:\/\/$PUBLIC_IP:8080\/fhir/" patient_browser_patch/default.json5
./setup_patient_browser.sh

