FROM  nvcr.io/nvidia/pytorch:23.01-py3

COPY conf/nlp/requirements.txt requirements.txt
RUN pip install -r requirements.txt

ARG INI_FILE
ARG AVRO_PATH

COPY $INI_FILE nlp-task.ini
COPY $AVRO_PATH/processed-rss-key.avsc .
COPY $AVRO_PATH/processed-rss-value.avsc .

COPY src/kafka/kafka_clients.py .
COPY src/nlp/nlp_task.py .
COPY src/utils/wranglers.py .

ENTRYPOINT ["python"]
CMD ["nlp_task.py"] 