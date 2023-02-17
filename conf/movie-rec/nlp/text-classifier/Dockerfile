FROM  nvcr.io/nvidia/pytorch:23.01-py3

COPY conf/movie-rec/nlp/requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY src/movie-rec/nlp/text-classifier/task.py task.py

ENTRYPOINT ["python"]
CMD ["task.py"] 