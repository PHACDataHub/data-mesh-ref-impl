FROM  python:3.11

COPY conf/kafka/requirements.txt requirements.txt
RUN pip install -r requirements.txt

ARG INI_FILE
ARG AVRO_PATH

COPY $INI_FILE .
COPY $AVRO_PATH/rss-value.avsc .
COPY $AVRO_PATH/processed-rss-key.avsc .
COPY $AVRO_PATH/processed-rss-value.avsc .

COPY src/kafka/kafka_clients.py .
COPY src/kafka/kafka_processor.py .
COPY src/utils/wranglers.py .

ENTRYPOINT ["python"]
CMD ["kafka_processor.py"] 