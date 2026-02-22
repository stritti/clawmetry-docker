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

USER clawmetry

EXPOSE 8900

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8900')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
# --host 0.0.0.0   listen on all interfaces (required in containers)
# --no-debug       not applicable under gunicorn; kept for backward compatibility
CMD ["--host", "0.0.0.0", "--port", "8900", "--no-debug"]
