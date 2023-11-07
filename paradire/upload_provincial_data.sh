#!/bin/bash

# Configurations
LOG_DIR="logs"
mkdir -p "$LOG_DIR"  # Create the logs directory if it doesn't exist
LOG_FILE="$LOG_DIR/upload.log"
SERVER_ADDRESS="http://localhost:8080"
provinces="AB BC MB NB NL NS NT NU ON PE QC SK YT"

# Logging function
log() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Health Check Function
check_health() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$SERVER_ADDRESS")
    if [ "$response" != "200" ]; then
        log "FHIR server is not healthy. Exiting."
        return 1
    else
        log "FHIR server is healthy."
        return 0
    fi
}

# Get user input for number of records
read -p "Enter the number of records you want to generate and upload: " record_count

# Validate record count
if ! [[ "$record_count" =~ ^[0-9]+$ ]]; then
    log "Invalid record count. Please enter a valid number."
    exit 1
fi

# Ask the user for provinces
echo "Enter the province abbreviations separated by space (e.g., AB BC MB NB NL NS NT NU ON PE QC SK YT). Type 'all' for all provinces."
read -a selected_provinces

if [[ "${selected_provinces[0]}" == "all" ]]; then
    selected_provinces=($provinces)
fi

# Sequentially generate and upload data for the selected provinces
for pt in "${selected_provinces[@]}"; do
    if [[ ! " $provinces " =~ " $pt " ]]; then
        log "Invalid province abbreviation: $pt. Skipping."
        continue
    fi

    # Check health before each upload
    if ! check_health; then
        log "Skipping upload for $pt due to FHIR server unavailability."
        continue
    fi

    log "Generating data for $pt..."
    ./generate_patient_population.sh "$record_count" "output_dir" "$pt"
    
    if [[ $? -ne 0 ]]; then
        log "Error occurred while generating data for $pt. Skipping upload for this province."
        continue
    fi

    log "Uploading data for $pt..."
    ./upload_pt_ehrs.sh "output_dir" "$pt"
    
    if [[ $? -ne 0 ]]; then
        log "Error occurred while uploading data for $pt."
    else
        log "Data for $pt uploaded successfully!"
    fi
done

log "All tasks completed!"