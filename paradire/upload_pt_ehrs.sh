#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <output_dir> <province_or_territory_abbreviation>"
    echo "Example: $0 output_dir AB"
    exit 1
fi

output_dir=$1
pt=$2

# Store the current directory to revert back to it later
curr_dir=$(pwd)

# Navigate to the synthea directory
cd ~/synthea

# Initialize counters for the number of records uploaded
hospital_records=0
practitioner_records=0
ehr_records=0

# Start timer
start_time=$(date +%s)

# Execute the upload scripts and count records (assuming one record per file)
hospital_records=$(./upload_hospitals.sh "$output_dir" "$pt" | wc -l)
practitioner_records=$(./upload_practitioners.sh "$output_dir" "$pt" | wc -l)
ehr_records=$(./upload_EHRs.sh "$output_dir" "$pt" | wc -l)

# End timer
end_time=$(date +%s)

# Calculate time taken
duration=$((end_time - start_time))

# Navigate back to the original directory
cd "$curr_dir"

# Display summary
echo "SUMMARY:"
echo "Uploaded $hospital_records hospital records."
echo "Uploaded $practitioner_records practitioner records."
echo "Uploaded $ehr_records EHR records."
echo "Total time taken: $duration seconds."