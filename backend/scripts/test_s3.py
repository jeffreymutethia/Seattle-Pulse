import sys
import os

# Add the parent directory to the system path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import boto3
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize the S3 client with the correct region
s3_client = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name="eu-north-1",  # Correct region for your bucket
    endpoint_url=os.getenv("S3_ENDPOINT_URL")  # Typically "https://s3.eu-north-1.amazonaws.com"
)

# List all buckets
try:
    response = s3_client.list_buckets()
    buckets = [bucket["Name"] for bucket in response.get("Buckets", [])]
    print("S3 Buckets:", buckets)
except Exception as e:
    print(f"Error connecting to S3: {e}")
