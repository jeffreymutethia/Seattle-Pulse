import time
import subprocess
import requests
import sys
import os
import argparse


def get_localstack_url(mode: str) -> str:
    if mode == "docker":
        return "http://localstack:4566"
    elif mode == "local":
        host = os.getenv("LOCALSTACK_HOST", "localhost")
        return f"http://{host}:4566"
    else:
        print("Invalid mode. Use 'docker' or 'local'.", file=sys.stderr)
        sys.exit(1)


def wait_for_localstack(localstack_url):
    print(f"Waiting for LocalStack to be ready at {localstack_url}...")
    while True:
        try:
            response = requests.head(f"{localstack_url}/_localstack/health")
            if response.status_code == 200:
                break
        except requests.ConnectionError:
            pass
        print(".", end="", flush=True)
        time.sleep(5)
    print("\nLocalStack is ready.")


def create_bucket(bucket_name, localstack_url):
    print(f"Creating S3 bucket '{bucket_name}'...")
    result = subprocess.run(
        [
            "aws",
            "--endpoint-url",
            localstack_url,
            "s3",
            "mb",
            f"s3://{bucket_name}",
            "--region",
            "us-east-1",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        print(f"S3 bucket '{bucket_name}' created successfully.")
    else:
        print(f"Failed to create S3 bucket '{bucket_name}'.", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Create S3 buckets in LocalStack.")
    parser.add_argument(
        "--mode",
        choices=["docker", "local"],
        default="local",
        help="Set the mode to run the script in (docker or local). Default is local.",
    )
    args = parser.parse_args()

    localstack_url = get_localstack_url(args.mode)
    print("Starting create_bucket.py script...")
    wait_for_localstack(localstack_url)

    # Create required buckets
    create_bucket("profile-images-bucket", localstack_url)
    create_bucket("thumbnail-images-bucket", localstack_url)
    create_bucket("chat-media-bucket", localstack_url)

    print("All S3 buckets have been successfully created in LocalStack!")
    print("create_bucket.py script completed.")


if __name__ == "__main__":
    main()
