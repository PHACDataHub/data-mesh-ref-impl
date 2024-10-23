# Use an official Python runtime as a base image
FROM python:3.8-slim

# Define the working directory for your Flask app inside the container
WORKDIR /app

# Copy the contents of the flask_app directory into the container's /app directory
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 80 for the Flask app
EXPOSE 80

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_DEBUG=0 

# Start the application using Gunicorn as the WSGI server
CMD ["gunicorn", "-w 4", "-b", ":80", "app:app"]
