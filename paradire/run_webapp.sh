#!/bin/bash

# Store the current directory to revert back to it later
curr_dir=$(pwd)

# Navigate to the webapp directory
cd "$(dirname "$0")/webapp"

# Check if virtual environment already exists; if not, create it
if [ ! -d "venv" ]; then
    # For Debian/Ubuntu users:
    sudo apt-get install python3-venv
    python3 -m venv venv
fi

# Check if the virtual environment was created successfully
if [ ! -d "venv" ]; then
    echo "Failed to create virtual environment. Exiting."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Failed to activate virtual environment. Exiting."
    exit 1
fi

# Install requirements
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install requirements. Exiting."
    exit 1
fi

# Set Flask environment variables
export FLASK_APP=app.py
export FLASK_ENV=development
export FLASK_RUN_PORT=5000

# Start Flask application
flask run
if [ $? -ne 0 ]; then
    echo "Failed to start Flask application. Exiting."
    exit 1
fi

# Deactivate virtual environment
deactivate

if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "Failed to deactivate virtual environment. Exiting."
    exit 1
fi

# Navigate back to the original directory
cd "$curr_dir"
