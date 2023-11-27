# Use confluentinc/cp-schema-registry as the base image
FROM confluentinc/cp-schema-registry:7.5.1

# Set the working directory
WORKDIR /workspace

# Switch to the root user for installations
USER root

# Install necessary packages
RUN yum install -y jq git bash curl bzip2 which findutils && \
    yum clean all && \
    rm -rf /var/cache/yum

# Download and install GNU Parallels
RUN curl -L https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2 -o parallel-latest.tar.bz2 \
    && tar -xjf parallel-latest.tar.bz2 \
    && (cd parallel-*/ && cp src/parallel /usr/local/bin/)

# Install Python and required Python packages
RUN pip3 install --upgrade pip && \
    pip3 install avro-python3

# Install Google Cloud SDK in a system-wide location
ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud
RUN curl -sSL https://sdk.cloud.google.com | bash -s -- --install-dir=$CLOUDSDK_INSTALL_DIR

# Set environment variables for Java and Google Cloud SDK
ENV JAVA_HOME /usr/lib/jvm/java-11-zulu-openjdk
ENV PATH $JAVA_HOME/bin:$PATH:$CLOUDSDK_INSTALL_DIR/google-cloud-sdk/bin

# Clone required repositories
RUN git clone https://github.com/synthetichealth/synthea.git && \
    git clone https://github.com/synthetichealth/synthea-international.git && \
    cp -fR synthea-international/ca/* synthea/

# Set permissions for the synthea directory
RUN chown -R appuser:appuser /workspace/synthea && \
    chmod -R 755 /workspace/synthea

# Set up environment variables for the application
ENV sampling_size=10 \
    pt=ab \
    fihr_server_url= \
    CONNECT_URL= \
    SCHEMA_URL= \
    BROKER_URL= \
    GCS_BUCKET= \
    CRON_JOB= \
    GOOGLE_APPLICATION_CREDENTIALS=

# Change to the synthea working directory
WORKDIR /workspace/synthea

# Copy Synthea scripts, configurations, and other necessary files
COPY synthea_patch/genenerate_ca_demo_sampling.sh ./
COPY synthea_patch/genenerate_pt_sampling.sh ./
COPY synthea_patch/upload_FHIR_data.sh ./
COPY synthea_patch/ca_data.tar.gz ./
COPY ./k8s/synthea-kafka/entrypoint.sh ./
COPY ./k8s/synthea-kafka/federal-cluster.sh ./
COPY ./k8s/synthea-kafka/pt-cluster.sh ./
COPY ./k8s/synthea-kafka/pt-cluster-cron.sh ./
COPY src/csv2avro.py ./
COPY synthea_patch/LifecycleModule.java ./src/main/java/org/mitre/synthea/modules/
COPY synthea_patch/synthea.properties ./src/main/resources/
COPY governance/events/ /workspace/governance/events/
RUN tar xvzf "ca_data.tar.gz" && \
    mv demographics_ca.csv src/main/resources/geography/ && \
    mv sdoh_ca.csv src/main/resources/geography/ && \
    mv insurance_plans_ca.csv src/main/resources/payers/ && \
    rm -f ca_data.tar.gz && \
    mkdir -p /data && chown -R appuser:appuser /data && chmod -R 755 /data

# Copy event and connector configurations
COPY ./analytics/v2_events/ /workspace/analytics/v2_events
COPY ./analytics/v2_pt_connectors/ /workspace/analytics/v2_pt_connectors
COPY ./analytics/v2_f_connectors/ /workspace/analytics/v2_f_connectors

# Modify JSON files in v2_pt_connectors and v2_f_connectors
RUN find /workspace/analytics/v2_pt_connectors /workspace/analytics/v2_f_connectors -type f -name '*.json' -exec sh -c 'jq ".config.\"key.converter.schema.registry.url\" = \"http://cp-schema-registry:8081\" | .config.\"value.converter.schema.registry.url\" = \"http://cp-schema-registry:8081\"" "$1" > temp.json && mv temp.json "$1"' sh {} \;

# Make sure scripts are executable
RUN chmod +x entrypoint.sh federal-cluster.sh pt-cluster.sh pt-cluster-cron.sh 

# Switch back to the non-root user
USER appuser

# Set the default command
CMD ["./entrypoint.sh"]
