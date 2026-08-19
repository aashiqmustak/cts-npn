# Docker Setup Guide

This guide provides instructions on how to set up and run the application using Docker and Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your machine.
- [Docker Compose](https://docs.docker.com/compose/install/) installed (usually included with Docker Desktop).

## Services Overview

The application consists of two main services managed by Docker Compose:

1. **Backend**: API server running on port `8000`.
   - Build context: `./` (Root directory)
   - Dockerfile: `infra/docker/backend.Dockerfile`
2. **Frontend**: Client application running on port `8080`.
   - Build context: `./` (Root directory)
   - Dockerfile: `infra/docker/frontend.Dockerfile`
Both services communicate over a custom bridge network named `app-network`.

## Setup Instructions

### 1. Environment Variables (Optional)

If your application requires specific environment variables, you can create a `.env` file in the root directory based on the provided `.env.example`:

```bash
# On Windows (Command Prompt)
copy .env.example .env

# On Linux/macOS/Git Bash
cp .env.example .env
```
*(Note: Currently, the `.env.example` provides a placeholder and no specific secrets are strictly required to start the basic setup).*

### 2. Build and Start the Application

To build the Docker images and start the containers, run the following command from the root directory of the project (where the `docker-compose.yaml` file is located):

```bash
docker-compose up --build
```
*(If you are using Docker Desktop with the Compose V2 plugin, you can also use `docker compose up --build`).*

This command will:
- Build the necessary images for the backend and frontend.
- Create the `app-network` network.
- Start the containers in the correct order (frontend depends on backend).

### 3. Access the Application

Once the terminal shows that the containers are running successfully, open your web browser and navigate to:

- **Frontend Application**: [http://localhost:8080](http://localhost:8080)
- **Backend API**: [http://localhost:8000](http://localhost:8000)

### 4. Stopping the Application

To gracefully stop the running containers, you can press `Ctrl+C` in the terminal where `docker-compose` is running.

To completely stop and remove the containers, networks, and any default volumes, run the following command from the root directory:

```bash
docker-compose down
```

## Useful Docker Commands

- **Run in detached mode** (background): 
  ```bash
  docker-compose up -d --build
  ```
- **View logs** (if running in detached mode): 
  ```bash
  docker-compose logs -f
  ```
- **Rebuild a specific service** (e.g., frontend):
  ```bash
  docker-compose up -d --build frontend
  ```
