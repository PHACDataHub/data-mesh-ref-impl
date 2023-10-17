# !/bin/sh

curr_dir=$(pwd)

for file in `ls $curr_dir/output/fhir/practitionerInformation*.json`; do
    echo $file
    # curl http://localhost:4004/hapi-fhir-jpaserver/fhir --data-binary "@$file" -H "Content-Type: application/fhir+json"
    curl http://localhost:8080/fhir --data-binary "@$file" -H "Content-Type: application/fhir+json"
    echo 
done