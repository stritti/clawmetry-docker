FROM python:3.12-slim

WORKDIR /app

ARG CLAWMETRY_VERSION=latest

RUN if [ "$CLAWMETRY_VERSION" = "latest" ]; then \
        pip install --no-cache-dir clawmetry; \
    else \
        pip install --no-cache-dir clawmetry==$CLAWMETRY_VERSION; \
    fi

EXPOSE 8900

ENTRYPOINT ["clawmetry"]
CMD ["--host", "0.0.0.0"]
