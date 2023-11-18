FROM alpine
ENV sampling_size=100
ENV pt=
ENV fihr_server_url=

WORKDIR /workspace

RUN apk update && apk add openjdk11 git bash jq parallel curl py3-pip && \
    pip install avro-python3 && \
    git clone https://github.com/synthetichealth/synthea.git && \
    git clone https://github.com/synthetichealth/synthea-international.git && \
    cp -fR synthea-international/ca/* synthea/

WORKDIR /workspace/synthea

COPY \
    synthea_patch/genenerate_ca_demo_sampling.sh \
    synthea_patch/genenerate_pt_sampling.sh \
    synthea_patch/upload_FHIR_data.sh \
    synthea_patch/ca_data.tar.gz \
    ./k8s/synthea/populate.sh \
    src/csv2avro.py \
    ./

COPY synthea_patch/LifecycleModule.java ./src/main/java/org/mitre/synthea/modules/
COPY synthea_patch/synthea.properties ./src/main/resources/

COPY governance/events/ /workspace/governance/events/

RUN tar xvzf "ca_data.tar.gz" && \
    mv demographics_ca.csv src/main/resources/geography/ && \
    mv sdoh_ca.csv src/main/resources/geography/ && \
    mv insurance_plans_ca.csv src/main/resources/payers/ && \
    mkdir /data


# VOLUME [ "/data" ]

CMD ["./populate.sh"]
