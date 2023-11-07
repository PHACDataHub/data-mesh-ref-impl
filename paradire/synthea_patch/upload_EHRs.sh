#!/bin/bash

# Store usage message in a variable
USAGE="Usage: $0 <output_dir> <province_or_territory_abbreviation>
where province_or_territory_abbreviation is one of:${valid_pt}
Example: $0 output_dir AB"

# Check and install necessary tools only if they're not present
for tool in parallel jq; do
    command -v $tool >/dev/null 2>&1 || { echo >&2 "$tool is not installed. Installing..."; sudo apt-get install -y $tool; }
done

valid_pt=" AB BC MB NB NL NS NT NU ON PE QC SK YT "

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

# Upload files
echo "Starting uploads..."
find "$output_dir/$pt/fhir/" -type f -name "*.json" ! -name "hospitalInformation*" ! -name "practitionerInformation*"  | parallel -j 16 upload_file {}
echo "Upload process completed!"
