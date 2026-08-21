# AWS Cloud Infrastructure & ML Model Hosting Guide

This document outlines the architecture, deployment workflows, and maintenance procedures for hosting the **CTS-NPN Machine Learning Inference Service** on **Amazon Web Services (AWS)** using **Litestar**, **Granian (Rust ASGI)**, **Docker**, **Amazon ECR**, and **Amazon EC2 / AWS App Runner**.

---

## 1. Architecture Overview

```
                          ┌────────────────────────┐
                          │   Frontend & Agents    │
                          │ (Flutter / Voice Bot)  │
                          └───────────┬────────────┘
                                      │ HTTP REST API
                                      ▼
                        ┌───────────────────────────┐
                        │   AWS EC2 / App Runner    │
                        │    (Port 8080 - HTTP)     │
                        ├───────────────────────────┤
                        │     Granian (Rust ASGI)   │
                        │     Litestar Framework    │
                        ├─────────────┬─────────────┤
                        │             │             │
                        ▼             ▼             ▼
                 /health Route   Adherence Model   Abandonment Model
                               (adherence_model)  (abandonment_model)
```

### Key Components

- **Inference Engine**: [Litestar](https://litestar.dev/) + [Granian](https://github.com/emmett-framework/granian) (high-performance Rust-based ASGI server).
- **Containerization**: Optimized Debian-based Docker image ([infra/docker/ml.Dockerfile](../infra/docker/ml.Dockerfile)).
- **Container Registry**: **Amazon ECR** (`cts-npn-ml`).
- **Compute Options**:
  - **Amazon EC2**: Dedicated virtual server with persistent container execution (`t3.small`/`t3.medium`).
  - **AWS App Runner**: Managed serverless container service with automatic HTTPS and auto-scaling.
- **Continuous Deployment**: GitHub Actions workflow ([.github/workflows/deploy-ml-apprunner.yml](../.github/workflows/deploy-ml-apprunner.yml)).

---

## 2. Models Hosted

| Model Name | Artifact Path | Algorithm | Purpose |
| :--- | :--- | :--- | :--- |
| **Medication Adherence Risk** | `ml-model/adherence/adherence_model.pkl` | Random Forest / Scikit-Learn | Predicts patient adherence likelihood (`LOW`, `MEDIUM`, `HIGH`) and probability distribution |
| **Prescription Abandonment** | `ml-model/abundant/abandonment_best_model_improved.pkl` | Logistic Regression Pipeline | Predicts probability of a patient abandoning medication due to friction/cost |

---

## 3. API Endpoints Specification

Base URL (Current Live Deployment): `http://3.238.40.150:8080`

### 3.1. Interactive Schema & OpenAPI Documentation
- **URL**: `GET /schema` (or `GET /schema/elements`)
- **Description**: Interactive UI to inspect and test all API parameters directly from a web browser.

### 3.2. Health Check
- **URL**: `GET /health`
- **Response**:
```json
{
  "status": "healthy",
  "models_loaded": {
    "adherence": true,
    "abandonment": true
  },
  "version": "1.0.0"
}
```

### 3.3. Medication Adherence Prediction
- **URL**: `POST /predict/adherence`
- **Request Payload**:
```json
{
  "previous_pdc_180": 0.85,
  "previous_pdc_365": 0.80,
  "refill_gap_days_90": 2,
  "refill_gap_days_180": 5,
  "access_friction_score": 0.2,
  "out_of_pocket_cost": 15.0,
  "estimated_patient_cost": 20.0,
  "concurrent_medications_count": 2,
  "current_medication_count": 1,
  "prior_medication_count": 3,
  "active_chronic_count": 1,
  "formulary_tier": 1,
  "prior_auth_required": 0,
  "access_friction_level": "LOW"
}
```
- **Response**:
```json
{
  "prediction": "LOW",
  "risk_scores": {
    "HIGH": 2.98,
    "LOW": 70.99,
    "MEDIUM": 26.03
  },
  "primary_risk_level": "LOW"
}
```

### 3.4. Prescription Abandonment Prediction
- **URL**: `POST /predict/abandonment`
- **Request Payload**:
```json
{
  "out_of_pocket_cost": 45.0,
  "estimated_patient_cost": 50.0,
  "formulary_tier": 3,
  "prior_auth_required": 1,
  "refill_gap_days_90": 0,
  "previous_pdc_180": 0.80,
  "active_chronic_count": 1,
  "access_friction_score": 0.30
}
```
- **Response**:
```json
{
  "abandonment_probability": 26.2,
  "is_abandonment_likely": false,
  "risk_category": "LOW"
}
```

---

## 4. Amazon ECR Container Registry Setup

- **Registry URI**: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/cts-npn-ml`
- **Example**: `164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml`

### Build & Push Image Manually (PowerShell)
```powershell
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 164167543673.dkr.ecr.us-east-1.amazonaws.com

# Build and Push
docker build -t cts-npn-ml:latest -f infra/docker/ml.Dockerfile .
docker tag cts-npn-ml:latest 164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml:latest
docker push 164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml:latest
```

*(Alternatively, run the automated script [infra/aws/deploy_ml.ps1](../infra/aws/deploy_ml.ps1)).*

---

## 5. Amazon EC2 Deployment Guide

### 5.1. EC2 Instance Configuration
- **Operating System**: Ubuntu 24.04 LTS (x86_64)
- **Instance Type**: `t3.small` (2 vCPU, 2 GB RAM) or `t3.medium`
- **Security Group Inbound Rules**:
  - `SSH` (Port 22) - Management access
  - `Custom TCP` (Port 8080) - `0.0.0.0/0` (Inference API traffic)
  - `HTTP` (Port 80) - Web traffic

### 5.2. Server Initialization Commands
On the Ubuntu EC2 server, execute:
```bash
# 1. Install Docker & AWS CLI
sudo apt-get update && sudo apt-get install -y docker.io awscli
sudo chmod 666 /var/run/docker.sock

# 2. Configure AWS CLI with IAM Deployer credentials
aws configure
# (Region: us-east-1)

# 3. Log in to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 164167543673.dkr.ecr.us-east-1.amazonaws.com

# 4. Start the ML container
docker run -d \
  --name ml-service \
  --restart always \
  -p 8080:8080 \
  164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml:latest
```

### 5.3. Updating the Container on EC2
To deploy a new model version or code update:
```bash
docker stop ml-service && docker rm ml-service
docker pull 164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml:latest
docker run -d --name ml-service --restart always -p 8080:8080 164167543673.dkr.ecr.us-east-1.amazonaws.com/cts-npn-ml:latest
```

---

## 6. AWS App Runner Deployment Guide (Serverless Alternative)

AWS App Runner provides fully managed container execution with auto-scaling and managed HTTPS domains.

### 6.1. Setup Steps
1. Navigate to **AWS Console** $\rightarrow$ **AWS App Runner** $\rightarrow$ **Create service**.
2. **Source**: Container registry $\rightarrow$ **Amazon ECR** $\rightarrow$ select `cts-npn-ml:latest`.
3. **Deployment Trigger**: `Automatic`.
4. **ECR Access Role**: `Create new service role` (`AppRunnerECRAccessRole`).
5. **Configuration**:
   - Port: `8080`
   - CPU / Memory: `1 vCPU` / `2 GB`
   - Health check path: `/health`
6. Click **Create & deploy**.

---

## 7. CI/CD Pipeline (GitHub Actions)

Located in [.github/workflows/deploy-ml-apprunner.yml](../.github/workflows/deploy-ml-apprunner.yml).

### Required GitHub Repository Secrets
Under **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions**:
- `AWS_ACCESS_KEY_ID`: IAM user access key.
- `AWS_SECRET_ACCESS_KEY`: IAM user secret key.
- `AWS_REGION`: AWS Region (e.g. `us-east-1`).

The workflow triggers on pushes touching `ml-model/**` or `server/src/ml_service/**`, automatically building the container in GitHub cloud runners and pushing the updated tag to Amazon ECR.

---

## 8. Monitoring & Troubleshooting

### Check Container Status
```bash
docker ps -a
```

### View Live Inference Logs
```bash
docker logs -f ml-service
```

### Restart Service
```bash
docker restart ml-service
```
