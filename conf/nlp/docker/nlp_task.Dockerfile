FROM  nvcr.io/nvidia/pytorch:23.01-py3

COPY conf/nlp/python/nlp_task_requirements.txt requirements.txt
RUN pip install -r requirements.txt

ARG INI_FILE

COPY $INI_FILE nlp_task.ini
COPY src/nlp/nlp_task.py nlp_task.py

ENTRYPOINT ["python"]
CMD ["nlp_task.py"] 