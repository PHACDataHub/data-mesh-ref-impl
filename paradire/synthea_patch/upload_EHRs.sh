#!/bin/sh

# Check and install necessary tools
command -v parallel >/dev/null 2>&1 || { echo >&2 "GNU Parallel is not installed. Installing..."; sudo apt-get install -y parallel; }

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
case "$valid_pt" in
    *" $pt "*) ;;
    *) echo "Invalid province or territory abbreviation. It should be one of:${valid_pt}"
       exit 1 ;;
esac

curr_dir=$(pwd)

# Use this function inline with GNU Parallel
find "$curr_dir/$output_dir/$pt/fhir/" -type f -name "*.json" ! -name "hospitalInformation*" ! -name "practitionerInformation*" | parallel 'file={}; echo "$file"; curl http://localhost:8080/fhir -H "Content-Type: application/fhir+json" --data-binary "@$file"; echo'
