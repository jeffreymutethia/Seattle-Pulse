# 🚀 LocalStack S3 Buckets Setup

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Running with Docker Compose (Recommended)](#running-with-docker-compose-recommended)
4. [Manual Docker Steps (Optional)](#manual-docker-steps-optional)
5. [Running Locally (Optional)](#running-locally-optional)
6. [Verifying Buckets](#verifying-buckets)
7. [Uploading Files](#uploading-files)
8. [Stopping LocalStack](#stopping-localstack)
9. [Notes on How It Works](#notes-on-how-it-works)

---

## 1. 📟 Introduction

This project sets up **three S3 buckets** using **LocalStack** automatically:

- `profile-images-bucket`
- `thumbnail-images-bucket`
- `chat-media-bucket`

LocalStack emulates AWS services locally for testing and development.

> ⚠️ **Note:** LocalStack **requires Docker** to run — whether you're using it in local mode or within a Docker container. Ensure Docker is installed and running before starting LocalStack.

Everything runs through Docker Compose so that services are initialized and ready to use without manual intervention.

---

## 2. ⚙️ Prerequisites

- **Docker** installed
- **Docker Compose** installed

---

## 3. 🐫 Running with Docker Compose (Recommended)

The easiest way to run everything is via Docker Compose. This will:

- Start LocalStack
- Build and run your Flask app
- Automatically create all necessary S3 buckets using the Python script inside the container

### ✅ Step 1: Start Everything

```bash
docker-compose up --build
```

> This will automatically:
>
> - Start LocalStack on port 4566
> - Wait for it to become healthy
> - Run `create_bucket.py --mode docker` from inside the Flask app container
> - Start the Flask server

---

## 4. 🛠️ Manual Docker Steps (Optional)

If you want more control over the process:

### ✅ Step 1: Start LocalStack with Docker CLI

```bash
docker run -d --name localstack-main -p 4566:4566 localstack/localstack
```

### ✅ Step 2: Run Flask App Container (that includes `create_bucket.py`)

```bash
docker build -t flask-app .
docker run --name flask-app-container --link localstack-main -p 5001:5001 flask-app
```

### ✅ Step 3: Manually Execute Bucket Script (if needed)

```bash
docker exec -it flask-app-container python create_bucket.py --mode docker
```

---

## 5. 💻 Running Locally 

### ✅ Step 1: Start LocalStack Locally

```bash
localstack start -d
```

> Make sure Docker is running since LocalStack depends on it even when running via CLI.

### ✅ Step 2: Run Script

```bash
python create_bucket.py --mode local
```

---

## 6. ✅ Verifying Buckets

To list all buckets:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

**Expected Output:**

```
2025-03-14 14:10:00 profile-images-bucket
2025-03-14 14:10:00 thumbnail-images-bucket
2025-03-14 14:10:00 chat-media-bucket
```

---

## 7. 📁 Uploading Files

### Upload a Profile Image

```bash
aws --endpoint-url=http://localhost:4566 s3 cp profile-pic.jpg s3://profile-images-bucket/
```

### Upload a Thumbnail

```bash
aws --endpoint-url=http://localhost:4566 s3 cp thumbnail.jpg s3://thumbnail-images-bucket/
```

### Upload a Chat Media File

```bash
aws --endpoint-url=http://localhost:4566 s3 cp chat-image.png s3://chat-media-bucket/
```

---

## 8. 🚫 Stopping LocalStack

To stop LocalStack:

```bash
localstack stop
```

To stop Docker containers:

```bash
docker-compose down
```

Or if using CLI directly:

```bash
docker stop localstack-main flask-app-container
```

---

## 9. 🧐 Notes on How It Works

| Component         | Description                                                              |
| ----------------- | ------------------------------------------------------------------------ |
| **LocalStack**    | Local AWS emulator for testing S3, DynamoDB, etc.                        |
| **AWS CLI**       | Interacts with LocalStack’s AWS services.                                |
| **Python Script** | `create_bucket.py` auto-creates all required S3 buckets.                 |
| **Docker**        | Ensures consistent environment for running apps and LocalStack together. |
| **Flask App**     | Connects to LocalStack's S3 buckets for local development use cases.     |

- The script supports a `--mode` flag: `local` or `docker`.
- Bucket creation logic is run via `entrypoint.py` before Flask starts.
- Full automation through `docker-compose up --build` ensures no manual bucket setup.

---

### 🌟 You're now set up to use LocalStack S3 buckets in any environment – local or Docker!

