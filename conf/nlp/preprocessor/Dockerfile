FROM  python:3.10

COPY conf/nlp/preprocessor/requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY conf/nlp/preprocessor/screenrant-rss-value.avsc screenrant-rss-value.avsc
COPY src/nlp/preprocessor.py preprocessor.py

ENTRYPOINT ["python"]
CMD ["preprocessor.py"] 
