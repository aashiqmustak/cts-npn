FROM python:3.13-bookworm

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy dependency definition files for caching
COPY pyproject.toml uv.lock ./

# Install dependencies (system libraries needed for building some python extension can go here if needed)
# Since we are on debian/slim, we might need a compiler/git for some deps, but uv sync can try directly first.
RUN sed -i 's/http:/https:/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/http:/https:/g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN uv sync --frozen --no-install-project

# Copy main entrypoint and the source code
COPY main.py ./
COPY server ./server

# Expose WebRTC server port
EXPOSE 8000

# Start the bot with WebRTC transport
CMD ["uv", "run", "python", "main.py", "-t", "webrtc", "--host", "0.0.0.0", "--port", "8000"]
