#!/bin/bash

# Define constants
valid_pt=" AB BC MB NB NL NS NT NU ON PE QC SK YT "
MAX_JOBS=$(nproc)

# Check and install necessary tools
for tool in parallel jq; do
    command -v $tool >/dev/null 2>&1 || { echo >&2 "$tool is not installed. Installing..."; sudo apt-get install -y $tool; }
done

# Usage message
USAGE="Usage: $0 <output_dir> <province_or_territory_abbreviation>
where province_or_territory_abbreviation is one of:${valid_pt}
Example: $0 output_dir AB"

# Check for script arguments and echo usage message if not correct
if [ $# -ne 2 ]; then
    echo "$USAGE"
    exit 1
fi

output_dir=$1
pt=$2

# Check if pt is a valid province or territory
if [[ ! "$valid_pt" =~ " $pt " ]]; then
    echo "Invalid province or territory abbreviation. It should be one of:${valid_pt}"
    exit 1
fi

# Upload function
upload_file() {
    file="$1"
    response=$(curl -s http://localhost:8080/fhir --data-binary "@$file" -H "Content-Type: application/fhir+json")
    if [[ "$response" == *"informational"* ]]; then
        echo "Successfully uploaded $file."
    else
        echo "Failed to upload $file."
    fi
}

export -f upload_file

# Upload hospital information
echo "Starting hospital information uploads..."
find "$output_dir/$pt/fhir/" -type f -name "hospitalInformation*.json" | parallel -j $MAX_JOBS upload_file {}
echo "Hospital information upload process completed!"

# Upload practitioner information
echo "Starting practitioner information uploads..."
find "$output_dir/$pt/fhir/" -type f -name "practitionerInformation*.json" | parallel -j $MAX_JOBS upload_file {}
echo "Practitioner information upload process completed!"

# Upload EHRs
echo "Starting EHR uploads..."
find "$output_dir/$pt/fhir/" -type f -name "*.json" ! -name "hospitalInformation*" ! -name "practitionerInformation*" | parallel -j $MAX_JOBS upload_file {}
echo "EHR upload process completed!"
