FROM python:3.12-slim

WORKDIR /app

ARG CLAWMETRY_VERSION=latest

RUN if [ "$CLAWMETRY_VERSION" = "latest" ]; then \
        pip install --no-cache-dir --root-user-action=ignore clawmetry; \
    else \
        pip install --no-cache-dir --root-user-action=ignore clawmetry==$CLAWMETRY_VERSION; \
    fi

# Create the default OpenClaw data directory so the container starts
# without requiring a volume mount (clawmetry auto-detects ~/.openclaw).
RUN mkdir -p /root/.openclaw

# Persist the OpenClaw workspace data outside the container.
VOLUME ["/root/.openclaw"]

EXPOSE 8900

ENTRYPOINT ["clawmetry"]
# --host 0.0.0.0   listen on all interfaces (required in containers)
# --no-debug       disable Flask auto-reloader (not suitable for containers)
CMD ["--host", "0.0.0.0", "--port", "8900", "--no-debug"]
