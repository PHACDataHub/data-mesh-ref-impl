#!/bin/bash

set -e

curr_dir=$(pwd)

cd 

if [ ! -d "hapi-fhir-jpaserver-starter" ]; then
    git clone https://github.com/hapifhir/hapi-fhir-jpaserver-starter.git
fi

cd hapi-fhir-jpaserver-starter

cp $curr_dir/hapi_fhir_patch/docker-compose.yml .
cp $curr_dir/hapi_fhir_patch/hapi.application.yaml .

docker compose up -d

cd $curr_dir