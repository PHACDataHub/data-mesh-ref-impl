#!/bin/bash

output_dir=$1
pt=$2

set -e

curr_dir=$(pwd)

cd ~/synthea

./upload_hospitals.sh $output_dir $pt
./upload_practitioners.sh $output_dir $pt
./upload_EHRs.sh $output_dir $pt

cd $curr_dir