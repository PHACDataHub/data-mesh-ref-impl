#!/bin/bash

set -euo pipefail

VENV_PATH="$HOME/Immunization_Gateway_ENV"
CSV_DIR=$1
SYMPTOMS_DIR=$2
AVRO_DIR=$3
LOG_DIR="logs"
[ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/csv2avro.log"

setup_venv() {
  echo "Setting up the Python virtual environment."
  [ ! -d "$VENV_PATH" ] && python3 -m venv "$VENV_PATH"
  source "$VENV_PATH/bin/activate"
  pip install --upgrade pip avro-python3
  deactivate
}

export VENV_PATH CSV_DIR SYMPTOMS_DIR AVRO_DIR

setup_venv

rm -rf $AVRO_DIR
mkdir -p "$AVRO_DIR"
[ ! -d "$AVRO_DIR" ] && mkdir -p "$AVRO_DIR"
source "$VENV_PATH/bin/activate"

python "src/csv2avro.py" "governance/events" "$CSV_DIR" "$SYMPTOMS_DIR" "$AVRO_DIR" 

deactivate
echo "Conversion to AVRO completed."