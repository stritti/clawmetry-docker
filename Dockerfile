# Stage 1: Build – install clawmetry into an isolated virtual environment
FROM python:3.14-slim AS builder

ARG CLAWMETRY_VERSION=latest

RUN python -m venv /venv

RUN if [ "$CLAWMETRY_VERSION" = "latest" ]; then \
        /venv/bin/pip install --no-cache-dir clawmetry[otel]; \
    else \
        /venv/bin/pip install --no-cache-dir clawmetry[otel]==$CLAWMETRY_VERSION; \
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

# Entrypoint script: translates clawmetry CLI flags to environment variables.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER clawmetry

EXPOSE 8900

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8900').read()" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
# --host 0.0.0.0   listen on all interfaces (required in containers)
# --no-debug       use Waitress (production server) instead of the Werkzeug dev server
CMD ["--host", "0.0.0.0", "--port", "8900", "--no-debug"]
