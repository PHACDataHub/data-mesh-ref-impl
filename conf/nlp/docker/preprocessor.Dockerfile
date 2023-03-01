FROM  python:3.10

COPY conf/nlp/python/preprocessor_requirements.txt requirements.txt
RUN pip install -r requirements.txt

ARG AVRO_PATH

COPY $AVRO_PATH/*.avsc .

COPY src/nlp/preprocessor.py preprocessor.py

ENTRYPOINT ["python"]
CMD ["preprocessor.py"] 
