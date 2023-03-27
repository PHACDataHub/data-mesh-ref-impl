#!/bin/bash

source .env

curl -L -o streamthoughts-kafka-connect-file-pulse-${KAFKA_CONNECT_FILEPULSE_VERSION}.zip https://github.com/streamthoughts/kafka-connect-file-pulse/releases/download/v${KAFKA_CONNECT_FILEPULSE_VERSION}/streamthoughts-kafka-connect-file-pulse-${KAFKA_CONNECT_FILEPULSE_VERSION}.zip
mv streamthoughts-kafka-connect-file-pulse-${KAFKA_CONNECT_FILEPULSE_VERSION}.zip kafka-ce/connect/plugins/.