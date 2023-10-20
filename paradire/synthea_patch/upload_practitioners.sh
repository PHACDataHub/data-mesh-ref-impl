# !/bin/sh

valid_pt="AB BC MB NB NL NS NT NU ON PE QC SK YT"

if [ -z "$2" ]; then
    echo "Usage: ./stream_pt_ehr_events.sh <province_or_territory_abbreviation>"
    echo "   where province_or_territory_abbreviation is one of: ${valid_pt}"
    echo "Example: ./stream_pt_ehr_events.sh AB"
    exit

    exit 1
fi

output_dir=$1
pt=$2

set -e

curr_dir=$(pwd)

for file in `ls $curr_dir/$output_dir/$pt/fhir/practitionerInformation*.json`; do
    echo $file
    # curl http://localhost:4004/hapi-fhir-jpaserver/fhir --data-binary "@$file" -H "Content-Type: application/fhir+json"
    curl http://localhost:8080/fhir --data-binary "@$file" -H "Content-Type: application/fhir+json"
    echo 
done