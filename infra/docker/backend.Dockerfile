FROM python:3.13-slim-bookworm

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy dependency definition files for caching
COPY pyproject.toml uv.lock ./

# Install minimal build tools and clean apt cache
RUN sed -i 's/http:/https:/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/http:/https:/g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"

RUN uv venv /app/.venv && \
    uv pip install --no-cache torch --index-url https://download.pytorch.org/whl/cpu && \
    uv pip install --no-cache -r pyproject.toml && \
    find /app/.venv -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Copy main entrypoint and the source code
COPY main.py ./
COPY server ./server
COPY dataset ./dataset

# Expose WebRTC server port
EXPOSE 8000

# Start the bot with WebRTC transport
CMD ["python", "main.py", "-t", "webrtc", "--host", "0.0.0.0", "--port", "8000"]
