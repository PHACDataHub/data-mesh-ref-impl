FROM  nvcr.io/nvidia/pytorch:23.01-py3

COPY conf/nlp/requirements.txt requirements.txt
RUN pip install -r requirements.txt

ARG INI_FILE
ARG AVRO_PATH

COPY $INI_FILE nlp_task.ini
COPY $AVRO_PATH/*.avsc .

COPY src/nlp/kafka_clients.py .
COPY src/nlp/nlp_task.py .
COPY src/nlp/wranglers.py .

ENTRYPOINT ["python"]
CMD ["nlp_task.py"] 