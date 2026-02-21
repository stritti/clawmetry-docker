# Stage 1: Build – install clawmetry into an isolated virtual environment
FROM python:3.14-slim AS builder

ARG CLAWMETRY_VERSION=latest

RUN python -m venv /venv

RUN if [ "$CLAWMETRY_VERSION" = "latest" ]; then \
        /venv/bin/pip install --no-cache-dir clawmetry; \
    else \
        /venv/bin/pip install --no-cache-dir clawmetry==$CLAWMETRY_VERSION; \
    fi

# Stage 2: Runtime – copy only the installed package, no build tools
FROM python:3.14-slim

COPY --from=builder /venv /venv

# Create the default OpenClaw data directory so the container starts
# without requiring a volume mount (clawmetry auto-detects ~/.openclaw).
RUN mkdir -p /root/.openclaw

# Persist the OpenClaw workspace data outside the container.
VOLUME ["/root/.openclaw"]

EXPOSE 8900

ENTRYPOINT ["/venv/bin/clawmetry"]
# --host 0.0.0.0   listen on all interfaces (required in containers)
# --no-debug       disable Flask auto-reloader (not suitable for containers)
CMD ["--host", "0.0.0.0", "--port", "8900", "--no-debug"]
