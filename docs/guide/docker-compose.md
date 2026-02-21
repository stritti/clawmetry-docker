# Docker Compose

An example [`docker-compose.yml`](https://github.com/stritti/clawmetry-docker/blob/main/docker-compose.yml) is included in the repository.
Copy it to your project and start the service:

```bash
docker compose up -d
```

Then open **http://localhost:8900** in your browser.

The file mounts your local `~/.openclaw` workspace into the container so the dashboard
can read logs, sessions, memory files, and metrics.
Uncomment the `environment` entries to customise the instance further.

## docker-compose.yml

```yaml
services:
  clawmetry:
    image: ghcr.io/stritti/clawmetry-docker:latest
    ports:
      # Map host port 8900 to container port 8900 (clawmetry web UI)
      - "8900:8900"
    volumes:
      # Mount the local OpenClaw workspace so the dashboard can read logs,
      # sessions, memory files, and metrics.
      - ~/.openclaw:/root/.openclaw
    environment:
      # Optional: explicitly set the OpenClaw data directory
      # OPENCLAW_DATA_DIR: /root/.openclaw
      # Optional: show your name in the Flow tab
      # OPENCLAW_USER: "Your Name"
      # Optional: Mission Control URL
      # MC_URL: "https://your-mission-control"
    restart: unless-stopped
```

## Environment variables in docker-compose

| Variable | Description |
|---|---|
| `OPENCLAW_DATA_DIR` | Explicit path to the OpenClaw data directory inside the container |
| `OPENCLAW_USER` | Your name shown in the Flow tab |
| `MC_URL` | Mission Control URL (disabled by default) |
