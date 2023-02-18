FROM  nvcr.io/nvidia/pytorch:23.01-py3

COPY conf/nlp/requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY src/nlp/question-answer/task.py task.py

ENTRYPOINT ["python"]
CMD ["task.py"] 