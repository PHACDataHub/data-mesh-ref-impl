FROM alpine:3.10 as builder

RUN apk update && apk upgrade && \
    apk add git wget openjdk8-jre-base py2-pip py2-curl && \
    pip install setuptools 

# install grepurl script to retrieve the most current download URL of CoreNLP
WORKDIR /opt
RUN git clone https://github.com/arne-cl/grepurl.git
WORKDIR /opt/grepurl
RUN python setup.py install

# install CoreNLP release 4.5.4
WORKDIR /opt
RUN wget --no-check-certificate https://nlp.stanford.edu/software/stanford-corenlp-4.5.4.zip && \
    unzip stanford-corenlp-4.5.4.zip && \
    mv $(ls -d stanford-corenlp-*/) corenlp && rm *.zip
# RUN wget https://huggingface.co/stanfordnlp/CoreNLP/resolve/main/stanford-corenlp-latest.zip && \
#     unzip stanford-corenlp-latest.zip && \
#     mv $(ls -d stanford-corenlp-*/) corenlp && rm *.zip

# install latest English language model
WORKDIR /opt/corenlp
RUN wget $(grepurl -r 'english.*jar$' -a http://stanfordnlp.github.io/CoreNLP | head -n 1)
# RUN wget https://huggingface.co/stanfordnlp/corenlp-english-extra/resolve/v4.5.4/stanford-corenlp-models-english-extra.jar

# only keep the things we need to run and test CoreNLP
FROM alpine:3.10

RUN apk update && apk add openjdk8-jre-base py3-pip && \
    pip3 install pytest pexpect requests

WORKDIR /opt/corenlp
COPY --from=builder /opt/corenlp .

ENV JAVA_XMX 16g
# ENV ANNOTATORS tokenize,pos,lemma,ner,regexner
ENV ANNOTATORS tokenize,ner,regexner
ENV REGEXNER /conf/regexner_mappings.tsv
ENV TIMEOUT_MILLISECONDS 300000
ENV PARSE_THREADS 32

ENV PORT 9000

EXPOSE $PORT

# CMD java -Xmx$JAVA_XMX -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -annotators "$ANNOTATORS" -port $PORT -timeout $TIMEOUT_MILLISECONDS -regexner.mapping $REGEXNER -regexner.ignorecase true -parse.nthreads $PARSE_THREADS

CMD java -Xmx$JAVA_XMX -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -annotators $ANNOTATORS -port $PORT -timeout $TIMEOUT_MILLISECONDS -ner.additional.regexner.mapping $REGEXNER -ner.additional.regexner.ignorecase true -parse.nthreads $PARSE_THREADS
