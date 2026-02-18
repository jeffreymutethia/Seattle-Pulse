# Seattle Pulse Backend

A **Flask**-based backend for the **Seattle Pulse** location-based social media app, designed for **scalability** and **extensibility**. This service provides RESTful APIs, database integration, and background task handling—laying the foundation for a modern social platform to rival TikTok, Instagram, and more.

---

## Table of Contents

1. [Overview](#overview)  
2. [Features](#features)  
3. [Technology Stack](#technology-stack)  
4. [Getting Started](#getting-started)  
   - [Prerequisites](#prerequisites)  
   - [Local Installation](#local-installation)  
   - [Configuration & Environment](#configuration--environment)  
   - [Database Migrations](#database-migrations)  
5. [Project Structure](#project-structure)  
6. [Running the Application](#running-the-application)  
   - [Local Development](#local-development)  
   - [Docker Compose](#docker-compose)  
   - [Celery Workers](#celery-workers)  
7. [Scripts & Utilities](#scripts--utilities)  
8. [Contributing](#contributing)  
   - [Branching](#branching)  
   - [Commit Conventions](#commit-conventions)  
   - [Pull Requests](#pull-requests)  
9. [Testing & Quality](#testing--quality)  
10. [Additional Resources](#additional-resources)  
11. [License](#license)

---

## Overview

The **Seattle Pulse Backend** is a Flask application providing:

- **User Authentication & Profiles**  
- **Content & Feed APIs**  
- **Comments, Reactions, & Event Management**  
- **Background Tasks** (via Celery) for fetching news, weather, etc.  
- **Database Migrations** (Alembic) to keep schema up-to-date

> **Note**: For the Next.js front-end, check out [Seattle Pulse Frontend](https://github.com/Seattle-Pulse/SEATTLE-PULSE-FRONTEND).

---

## Features

- **RESTful Endpoints**: Organized in `/app/api/*`, covering authentication, feed, profile, and more.  
- **Fetchers & Tasks**: Background tasks for news/weather ingestion, leveraging **Celery** + **Redis**.  
- **Local AWS Mock**: Optional **LocalStack** usage for S3-like storage in dev/test environments.  
- **Rate Limiting**: Basic API rate limiting via Flask or custom logic.  
- **Error Handling**: Centralized error handling to keep responses consistent.

---

## Technology Stack

- **Python 3.10+**  
- **Flask** (RESTful APIs)  
- **PostgreSQL** (Primary database)  
- **SQLAlchemy** (ORM)  
- **Alembic** (Database migrations)  
- **Celery** (Asynchronous background tasks)  
- **Redis** (Broker/Cache for Celery)  
- **Docker & Docker Compose** (Optional for containerized dev environment)

---

## Getting Started

### Prerequisites

1. **Python 3.10+**  
2. **PostgreSQL** (Local or remote)  
3. **Redis** (If running Celery tasks)  
4. **Git**  
5. (Optional) **Docker** + **Docker Compose**

> **Recommended**: Use [pyenv](https://github.com/pyenv/pyenv) to manage multiple Python versions, or any standard approach (brew, apt-get, etc.).

### Local Installation

1. **Clone the Repo**  
   ```bash
   git clone https://github.com/Seattle-Pulse/SEATTLE-PULSE-BACKEND.git
   cd SEATTLE-PULSE-BACKEND
   ```

2. **Create & Activate a Virtual Environment**  
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**  
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

### Configuration & Environment

Copy or create a `.env` file (ignored by Git) in the project root. Example:

```bash
# .env

# Database
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_db_pass
POSTGRES_DB=your_db_name
DATABASE_URL=postgresql://your_db_user:your_db_pass@localhost:5432/your_db_name

# Flask
FLASK_ENV=development
SECRET_KEY=some-random-secret

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# AWS / LocalStack
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
S3_ENDPOINT_URL=http://localhost:4566
```

> **Security Reminder**: Never commit real passwords or secrets. Use a password manager or environment-specific secrets manager (e.g., AWS Secrets Manager).

### Database Migrations

We use **Alembic** to handle schema changes.

```bash
# Run existing migrations
flask db upgrade

# Generate a new migration script after model changes
flask db revision --autogenerate -m "Describe changes"
```

---

## Project Structure

```
SEATTLE-PULSE-BACKEND/
├── app/
│   ├── api/
│   │   ├── auth.py
│   │   ├── comment.py
│   │   ├── content.py
│   │   ├── ...
│   ├── fetchers/
│   │   ├── news_fetcher.py
│   │   ├── weather_fetcher.py
│   ├── models.py
│   ├── ...
├── migrations/
│   ├── env.py
│   ├── versions/
│   ├── alembic.ini
├── scripts/
│   ├── seed.py
│   └── remove_all_dbs.py
├── requirements.txt
├── run.py
├── docker-compose.yml
├── Dockerfile
└── ...
```

- **app/**: Main Flask code, including routes (`/api/`), models, config, etc.  
- **migrations/**: Alembic scripts for DB schema changes.  
- **scripts/**: Additional utilities (seeding DB, removing old databases).  
- **run.py**: Entry point for running the Flask server.  
- **docker-compose.yml**: Orchestrates local dev environment (PostgreSQL, Redis, LocalStack, etc.).

---

## Running the Application

### Local Development

1. **Activate Virtual Env**  
   ```bash
   source venv/bin/activate
   ```
2. **Initialize DB**  
   ```bash
   flask db upgrade
   ```
3. **Run the Server**  
   ```bash
   python run.py
   ```

Server typically listens on [http://127.0.0.1:5001](http://127.0.0.1:5001).

### Docker Compose

For a complete environment with PostgreSQL, Redis, and LocalStack:

```bash
docker-compose up --build
```

- **db**: PostgreSQL container  
- **redis**: For Celery  
- **localstack**: AWS mock (S3, etc.)  
- **web**: Your Flask app container  
- **celery-worker**, **celery-beat**: For asynchronous tasks

> **Pro Tip**: Inspect the `docker-compose.yml` to see how containers link together.

### Celery Workers

To run background tasks (e.g., news or weather fetching):
- **Celery Worker**:  
  ```bash
  celery -A app.celery worker --loglevel=info
  ```
- **Celery Beat** (Scheduled tasks):  
  ```bash
  celery -A app.celery beat --loglevel=info
  ```

If using Docker Compose, these run automatically in separate containers.

---

## Scripts & Utilities

- **`create_bucket.py`**: Helps create S3 buckets on LocalStack for local dev.  
- **`scripts/seed.py`**: Seeds the database with initial data.  
- **`scripts/remove_all_dbs.py`**: Utility for wiping dev/test databases.  

> Carefully review each script before running to avoid data loss in production.

---

## Contributing

We appreciate community input and PRs! Follow the same guidelines as our front-end repo:

### Branching

- **main**: Always production-ready.  
- **feature/short-description**: New features or significant changes.  
- **hotfix/short-description**: Urgent bug or security fixes.

```bash
git checkout -b feature/advanced-notifications
```

### Commit Conventions

```
[Fix] Resolved race condition in Celery news fetch

- Replaced naive scheduling with robust approach
- Updated unit tests
```

### Pull Requests

1. **Push your branch**:
   ```bash
   git push origin feature/advanced-notifications
   ```
2. **Open a PR** on GitHub.  
3. **Provide context** (issue link, screenshots).  
4. **Merge** when approved.

---

## Testing & Quality

- **Python Unit Tests**: If you have a `tests/` folder, you can run them with:
  ```bash
  pytest
  ```
- **Linting/Style**: Use [Flake8](https://flake8.pycqa.org/) or [Black](https://black.readthedocs.io/en/stable/) to enforce coding standards:
  ```bash
  pip install flake8 black
  black app/ --check
  ```
- **Integration Tests**: Could be done via scripts or frameworks like [Postman/Newman](https://learning.postman.com/docs/running-collections/using-newman-cli/) or [pytest + requests](https://docs.pytest.org/en/stable/).

---

## Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/en/latest/)  
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/en/14/)  
- [Celery Docs](https://docs.celeryproject.org/en/stable/)  
- [Alembic Migrations](https://alembic.sqlalchemy.org/en/latest/)  

---

## License

All rights reserved.  
This project is proprietary and confidential. Unauthorized copying of this project, via any medium, is strictly prohibited.
