FROM public.ecr.aws/lambda/python:3.10

# Set /var/task as the working directory
WORKDIR /var/task

# Copy the requirements file and install dependencies
COPY requirements.txt /var/task/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire app directory
COPY app /var/task/app

# Copy the root directory files (including config.py)
COPY . /var/task/

# Copy the Lambda entrypoint
COPY lambda-news-fetcher/lambda_handler.py /var/task/lambda_handler.py

# Setting the Lambda handler 
CMD ["lambda_handler.handler"]