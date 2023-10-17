#!/bin/bash

if [ ! -z "$1" ]; then
    sampling_size=100
else
    sampling_size=$1
fi

set -e

gh repo clone synthetichealth/synthea
gh repo clone synthetichealth/synthea-international

cd synthea-international
cp -R ca/* ../synthea

cd ..

for item in genenerate_ca_demo_sampling genenerate_ca_equi_sampling upload_EHRs upload_hospitals upload_practitioners
do
    cp synthea_patch/$item.sh synthea/.
    chmod +x synthea/$item.sh
done

cp synthea_patch/LifecycleModule.java synthea/src/main/java/org/mitre/synthea/modules/.

cd synthea_patch

tar xvzf ca_data.tar.gz 

cp demographics_ca.csv synthea/src/main/resources/geography/.
cp sdoh_ca.csv synthea/src/main/resources/geography/.
cp insurance_plans_ca.csv synthea/src/main/resources/payers/.

cp synthea.properties synthea/src/main/resources/.

cd ../synthea

rm -rf output

./genenerate_ca_equi_sampling.sh $sampling_size