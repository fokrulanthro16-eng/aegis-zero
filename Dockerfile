# AegisZero: Sovereign Edge Zero-Latency Kernel
# Multi-stage lightweight production container

FROM python:3.11-slim

# Prevent Python from writing .pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install pinned requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY agent/ ./agent/
COPY web/ ./web/
COPY docs/ ./docs/
COPY mock_kb/ ./mock_kb/ 2>/dev/null || true
COPY PRD.md .
COPY README.md .
COPY LICENSE .

# Create non-root user for defense-grade security
RUN useradd -m -u 1000 aegisuser && chown -R aegisuser:aegisuser /app
USER aegisuser

EXPOSE 8080

# Healthcheck to verify kernel response
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Launch AegisZero Sovereign Edge Server
ENTRYPOINT ["python", "agent/main.py", "--port", "8080", "--host", "0.0.0.0"]
