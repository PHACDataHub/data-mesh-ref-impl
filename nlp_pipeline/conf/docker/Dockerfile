ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG WORKFLOW_FILE
ARG WORKFLOW_NAME
ARG STEP_NAME
ARG PYTHON_REQUIREMENTS
ARG AVRO_DIR

COPY $PYTHON_REQUIREMENTS requirements.txt
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY .env .

COPY $AVRO_DIR/*.avsc .

COPY $WORKFLOW_FILE .

COPY src/common/*.py .
COPY src/$STEP_NAME.py worker.py

ENV __WORKFLOW_FILE=${WORKFLOW_FILE}
ENV __WORKFLOW_NAME=${WORKFLOW_NAME}
ENV __STEP_NAME=${STEP_NAME}

RUN echo python main.py ${__WORKFLOW_FILE} ${__WORKFLOW_NAME} ${__STEP_NAME}

CMD python main.py ${__WORKFLOW_FILE} ${__WORKFLOW_NAME} ${__STEP_NAME}

# Use this for test
# CMD python worker.py
