FROM python:3.12-slim

WORKDIR /app

# Install system build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies for Litestar & ML inference
RUN pip install --no-cache-dir \
    "litestar>=2.15.0" \
    "msgspec>=0.18.6" \
    "granian[reload]>=2.6.1" \
    "scikit-learn>=1.5.0" \
    "xgboost>=2.0.0" \
    "pandas>=2.2.0" \
    "numpy>=1.26.0" \
    "joblib>=1.4.0"

# Copy ML model artifacts
COPY ml-model /app/ml-model

# Copy ML service source code
COPY server/src/ml_service /app/server/src/ml_service

# Environment variables
ENV PYTHONPATH="/app/server/src"
ENV ADHERENCE_MODEL_PATH="/app/ml-model/adherence/adherence_model.pkl"
ENV ABANDONMENT_MODEL_PATH="/app/ml-model/abundant/abandonment_best_model_improved.pkl"

# AWS App Runner default port
EXPOSE 8080

# Launch high-performance Granian ASGI server
CMD ["granian", "--interface", "asgi", "--host", "0.0.0.0", "--port", "8080", "--workers", "2", "ml_service.app:app"]
