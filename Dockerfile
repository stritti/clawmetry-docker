# Stage 1: Build – install clawmetry + gunicorn into an isolated virtual environment
FROM python:3.14-slim AS builder

ARG CLAWMETRY_VERSION=latest

RUN python -m venv /venv

RUN if [ "$CLAWMETRY_VERSION" = "latest" ]; then \
        /venv/bin/pip install --no-cache-dir clawmetry[otel] gunicorn; \
    else \
        /venv/bin/pip install --no-cache-dir clawmetry[otel]==$CLAWMETRY_VERSION gunicorn; \
    fi

# Stage 2: Runtime – copy only the installed package, no build tools
FROM python:3.14-slim

COPY --from=builder /venv /venv

# Create a non-root user to run the application.
RUN useradd -m -u 1000 clawmetry

# Install gosu to drop privileges safely.
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/*

# Create the default OpenClaw data directory so the container starts
# without requiring a volume mount (clawmetry auto-detects ~/.openclaw).
RUN mkdir -p /home/clawmetry/.openclaw && \
    chown -R clawmetry:clawmetry /home/clawmetry/.openclaw

# Persist the OpenClaw workspace data outside the container.
VOLUME ["/home/clawmetry/.openclaw"]

# Application directory – gunicorn imports wsgi.py from here.
WORKDIR /app
COPY wsgi.py .

# Entrypoint script: translates clawmetry CLI flags to gunicorn options.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# SECURITY NOTE:
# The container intentionally starts as root so that entrypoint.sh can perform any
# required permission and ownership fixes (e.g., chown/chmod on mounted volumes)
# before the application runs. The script is expected to call 'gosu' as early as
# possible to drop privileges to the non-root 'clawmetry' user for the actual
# application process.
# This increases the attack surface if a vulnerability exists in the portion of
# entrypoint.sh that runs before 'gosu'. Keep that logic minimal, avoid parsing
# untrusted input there, and review any changes to entrypoint.sh carefully.

EXPOSE 8900

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8900').read()" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
# --host 0.0.0.0   listen on all interfaces (required in containers)
# --no-debug       not applicable under gunicorn; kept for backward compatibility
CMD ["--host", "0.0.0.0", "--port", "8900", "--no-debug"]
