#!/bin/bash

setup_environment() {
    cd
    # Ensure Java is installed
    if [ -z "$(which java)" ]; then
        echo "Java not found. Installing..."
        sudo apt install default-jdk -y
    fi

    # Clone and setup repositories only if they do not exist
    if [ ! -d "synthea" ]; then
        echo "Cloning synthea repository..."
        git clone https://github.com/synthetichealth/synthea.git
    fi

    if [ ! -d "synthea-international" ]; then
        echo "Cloning synthea-international repository..."
        git clone https://github.com/synthetichealth/synthea-international.git
        echo "Copying contents from synthea-international to synthea..."
        cp -fR synthea-international/ca/* synthea/
    fi
}

update_synthea() {
    # Update synthea with necessary files and scripts
    cd synthea
    echo "Updating synthea with necessary files..."
    for script in genenerate_ca_demo_sampling genenerate_pt_sampling upload_FHIR_data; do
        cp "$curr_dir/synthea_patch/$script.sh" .
    done

    cp "$curr_dir/synthea_patch/LifecycleModule.java" src/main/java/org/mitre/synthea/modules/
    tar xvzf "$curr_dir/synthea_patch/ca_data.tar.gz"
    mv demographics_ca.csv src/main/resources/geography/
    mv sdoh_ca.csv src/main/resources/geography/
    mv insurance_plans_ca.csv src/main/resources/payers/
    cp "$curr_dir/synthea_patch/synthea.properties" src/main/resources/
}

generate_data() {
    # Generate patient data and move to output directory
    rm -rf output
    echo "Generating patient data for $pt..."
    ./genenerate_pt_sampling.sh $sampling_size $output_dir $pt
}

# Main execution starts here
curr_dir=$(pwd)
sampling_size=${1:-100}
output_dir=${2:-ca_spp}
pt=${3:-ON}

setup_environment
update_synthea
generate_data

cd $curr_dir