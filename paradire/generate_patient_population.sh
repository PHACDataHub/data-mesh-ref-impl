#!/bin/bash

has_jdk=$(which java)

if [ -z "$has_jdk" ]; then
    sudo apt install default-jdk -y
fi

# Assign default values to arguments if not provided
sampling_size=${1:-100}
output_dir=${2:-ca_spp}
pt=${3:-ON}

set -e

curr_dir=$(pwd)

cd 

if [ ! -d "synthea" ]; then
    git clone https://github.com/synthetichealth/synthea.git
fi

if [ ! -d "synthea-international" ]; then
    git clone https://github.com/synthetichealth/synthea-international.git
    cd synthea-international
    cp -fR ca/* ../synthea
    cd ..
fi

cd synthea

for item in genenerate_ca_demo_sampling genenerate_pt_sampling upload_EHRs upload_hospitals upload_practitioners
do
    cp $curr_dir/synthea_patch/$item.sh .
done

output=

cp -f $curr_dir/synthea_patch/LifecycleModule.java src/main/java/org/mitre/synthea/modules/.

tar xvzf $curr_dir/synthea_patch/ca_data.tar.gz

mv -f demographics_ca.csv src/main/resources/geography/.
mv -f sdoh_ca.csv src/main/resources/geography/.
mv -f insurance_plans_ca.csv src/main/resources/payers/.

cp -f $curr_dir/synthea_patch/synthea.properties src/main/resources/.

rm -rf output

./genenerate_pt_sampling.sh $sampling_size $output_dir $pt

cd $curr_dir