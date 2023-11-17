# Use confluentinc/cp-schema-registry as base image
FROM confluentinc/cp-schema-registry:7.5.1

# Set the working directory
WORKDIR /workspace

# Switch to root user for installation
USER root

# Install necessary packages
RUN yum install -y jq git bash curl python3-pip \
    && yum install -y java-11-openjdk-devel \
    && yum install -y bzip2

# Set JAVA_HOME (replace /path/to/java with actual Java path)
ENV JAVA_HOME /usr/lib/jvm/java-11-zulu-openjdk
ENV PATH $JAVA_HOME/bin:$PATH

# Download and install GNU Parallel
RUN curl -L https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2 -o parallel-latest.tar.bz2 \
    && tar -xjf parallel-latest.tar.bz2 \
    && (cd parallel-*/ && cp src/parallel /usr/local/bin/)

# Install Python packages
RUN pip3 install --upgrade pip \
    && pip3 install avro-python3

# Clone repositories
RUN git clone https://github.com/synthetichealth/synthea.git \
    && git clone https://github.com/synthetichealth/synthea-international.git \
    && cp -fR synthea-international/ca/* synthea/

# Correct permissions for the synthea directory
RUN chown -R appuser:appuser /workspace/synthea \
    && chmod -R 755 /workspace/synthea

# Setting up environment variables
ENV sampling_size=10
ENV pt=AB
ENV fihr_server_url=http://localhost:8080
ENV CONNECT_URL=http://10.162.0.11:8083
ENV SCHEMA_URL=http://10.162.0.11:8081
ENV BROKER_URL=http://10.162.0.11:9093

# Setting the working directory to /workspace/synthea
WORKDIR /workspace/synthea

# Copying Synthea scripts, configurations, and other necessary files
COPY synthea_patch/genenerate_ca_demo_sampling.sh ./
COPY synthea_patch/genenerate_pt_sampling.sh ./
COPY synthea_patch/upload_FHIR_data.sh ./
COPY synthea_patch/ca_data.tar.gz ./
COPY ./k8s/synthea-kafka/synthea-kafka.sh ./
COPY src/csv2avro.py ./
COPY synthea_patch/LifecycleModule.java ./src/main/java/org/mitre/synthea/modules/
COPY synthea_patch/synthea.properties ./src/main/resources/
COPY governance/events/ /workspace/governance/events/
RUN tar xvzf "ca_data.tar.gz" \
    && mv demographics_ca.csv src/main/resources/geography/ \
    && mv sdoh_ca.csv src/main/resources/geography/ \
    && mv insurance_plans_ca.csv src/main/resources/payers/ && \
    mkdir /data

COPY ./analytics/v2_events/ /workspace/analytics/v2_events
COPY ./analytics/v2_pt_connectors/ /workspace/analytics/v2_pt_connectors

RUN mkdir -p /data && chown -R appuser:appuser /data && chmod -R 755 /data

# Set the user back to appuser
USER appuser

CMD ["./synthea-kafka.sh"]
