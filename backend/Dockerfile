# Use Python slim image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Install system dependencies for AWS CLI
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN pip install --no-cache-dir awscli

# Copy the requirements file and install dependencies
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Copy the entrypoint script from the root folder
COPY entrypoint.py /entrypoint.py
COPY create_bucket.py /create_bucket.py

# Set environment variables for Flask
ENV FLASK_APP=run.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_ENV=development  

# Expose port for Flask
EXPOSE 5000

# Configure logging for Docker
ENV PYTHONUNBUFFERED=1
ENV LOGGING_LEVEL=DEBUG

# Set the default entrypoint
ENTRYPOINT ["python", "/entrypoint.py"]