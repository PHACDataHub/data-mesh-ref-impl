#!/bin/bash

# Check and install necessary tools
command -v parallel >/dev/null 2>&1 || { echo >&2 "GNU Parallel is not installed. Installing..."; sudo apt-get install -y parallel; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Installing..."; sudo apt-get install -y jq; }

valid_pt=" AB BC MB NB NL NS NT NU ON PE QC SK YT "

if [ $# -ne 2 ]; then
    echo "Usage: $0 <output_dir> <province_or_territory_abbreviation>"
    echo "   where province_or_territory_abbreviation is one of:${valid_pt}"
    echo "Example: $0 output_dir AB"
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
        echo "Successfully uploaded $file"
    else
        echo "Failed to upload $file. Server response: $response"
    fi
}

export -f upload_file

echo "Starting uploads..."
find "$output_dir/$pt/fhir/" -type f -name "hospitalInformation*.json" | parallel -j 16 upload_file {}
echo "Upload process completed!"
