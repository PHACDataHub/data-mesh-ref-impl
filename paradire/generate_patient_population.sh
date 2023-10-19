#!/bin/bash

has_jdk=$(which java)

if [ -z "$has_jdk" ]; then
    sudo apt install default-jdk -y
fi

if [ -z "$1" ]; then
    sampling_size=100
else
    sampling_size=$1
fi

if [ -z "$2" ]; then
    output_dir=ca_spp
else
    output_dir=$2
fi

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

for item in genenerate_ca_demo_sampling genenerate_ca_equi_sampling upload_EHRs upload_hospitals upload_practitioners
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

./genenerate_ca_equi_sampling.sh $sampling_size $output_dir

cd $curr_dir