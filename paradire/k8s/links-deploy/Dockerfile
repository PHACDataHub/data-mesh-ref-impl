# Use an official Python runtime as a base image
FROM python:3.8-slim

# Define the working directory for your Flask app
WORKDIR /app

# Copy your Flask application files into the container at /app
COPY /flask_app /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_DEBUG=0 

# Start the application using Gunicorn as the WSGI server
CMD ["gunicorn", "-w 4", "-b", ":80", "app:app"]