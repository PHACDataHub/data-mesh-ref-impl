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

# Start timer
start_time=$(date +%s)

# Execute the upload scripts
echo "--------------------------"
echo "Uploading hospital records..."
./upload_hospitals.sh "$output_dir" "$pt"
echo "--------------------------"

echo "Uploading practitioner records..."
./upload_practitioners.sh "$output_dir" "$pt"
echo "--------------------------"

echo "Uploading EHR records..."
./upload_EHRs.sh "$output_dir" "$pt"
echo "--------------------------"

# End timer
end_time=$(date +%s)

# Calculate time taken
duration=$((end_time - start_time))

# Display summary
echo "UPLOAD SUMMARY:"
echo "Total time taken: $duration seconds."
echo "Upload process completed!"