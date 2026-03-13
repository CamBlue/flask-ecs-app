# =============================================================================
# Stage 1: Builder
# Purpose: Install Python dependencies into a virtual environment.
# This stage uses a full Python image so pip can compile any C extensions.
# =============================================================================
FROM python:3.12-slim AS builder

# Set working directory inside the builder container
WORKDIR /app

# Copy only the requirements file first.
# Docker caches layers. If requirements.txt hasn't changed, this entire
# layer is served from cache on subsequent builds � much faster.
COPY requirements.txt .

# Create a virtual environment and install dependencies into it.
# Using a venv means we can copy just the venv folder to the final stage
# without dragging along pip, setuptools, or the rest of the Python toolchain.
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip --quiet && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# =============================================================================
# Stage 2: Final (Production) Image
# Purpose: Minimal runtime image. No build tools, no cache, no pip.
# =============================================================================
FROM python:3.12-slim AS final

# Create a non-root user to run the application.
# Running as root inside a container is a security risk � if the process
# is compromised, the attacker has root inside the container.
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy the virtual environment from the builder stage (not from host)
COPY --from=builder /opt/venv /opt/venv

# Copy application source code
COPY app.py .

# Set environment variables
# PATH: make the venv's binaries (including gunicorn) available
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    COMMIT_SHA=unknown
    ENV ENVIRONMENT=production

# Switch to non-root user
USER appuser

# Expose the port Gunicorn will listen on
EXPOSE 5000

# Healthcheck: Docker (and ECS) can use this to monitor container health.
# Calls the /health endpoint every 30 seconds.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

# Start the app with Gunicorn.
# --workers 2: two worker processes (good for Fargate 0.5 vCPU)
# --bind 0.0.0.0:5000: listen on all interfaces, port 5000
# --access-logfile -: write access logs to stdout (captured by CloudWatch)
# --error-logfile -: write error logs to stdout
# app:app: the Python module "app", the Flask object named "app"
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5000", \
     "--access-logfile", "-", "--error-logfile", "-", \
     "--timeout", "60", "app:app"]
