# clawmetry-docker

Docker Image for [clawmetry](https://clawmetry.com/) — real-time observability dashboard for [OpenClaw](https://github.com/openclaw/openclaw) AI agents.

The image is built automatically from the latest [clawmetry PyPI release](https://pypi.org/project/clawmetry/) and published to both [Docker Hub](https://hub.docker.com/r/stritti/clawmetry) and the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker).

## Usage

### Quickstart

**Docker Hub:**
```bash
docker run -p 8900:8900 stritti/clawmetry:latest
```

**GitHub Container Registry:**
```bash
docker run -p 8900:8900 ghcr.io/stritti/clawmetry-docker:latest
```

Then open **http://localhost:8900** in your browser.

### Mount your OpenClaw data directory (recommended)

Clawmetry auto-detects the OpenClaw workspace at `~/.openclaw` (= `/root/.openclaw` inside the container).
Mount your host workspace to that path so the dashboard can read logs, sessions, memory files, and metrics:

```bash
docker run -p 8900:8900 \
  -v ~/.openclaw:/root/.openclaw \
  stritti/clawmetry:latest
```

Or pass a custom path explicitly:

```bash
docker run -p 8900:8900 \
  -v /path/to/workspace:/data \
  stritti/clawmetry:latest --data-dir /data
```

### Environment variables

All CLI flags can alternatively be set via environment variables:

| Variable | CLI equivalent | Description |
|---|---|---|
| `OPENCLAW_HOME` | `--workspace` | Path to the agent workspace directory |
| `OPENCLAW_DATA_DIR` | `--data-dir` | OpenClaw data dir (auto-sets workspace, sessions, crons) |
| `OPENCLAW_LOG_DIR` | `--log-dir` | Directory containing agent log files |
| `OPENCLAW_SESSIONS_DIR` | `--sessions-dir` | Directory containing session `.jsonl` files |
| `OPENCLAW_USER` | `--name` | Your name shown in the Flow tab |
| `MC_URL` | `--mc-url` | Mission Control URL (disabled by default) |
| `CLAWMETRY_FLEET_KEY` | `--fleet-api-key` | API key for multi-node fleet authentication |

Example with environment variables:

```bash
docker run -p 8900:8900 \
  -e OPENCLAW_DATA_DIR=/root/.openclaw \
  -v ~/.openclaw:/root/.openclaw \
  stritti/clawmetry:latest
```

### docker-compose

An example [`docker-compose.yml`](docker-compose.yml) is included in this repository.
Copy it to your project and start the service with:

```bash
docker compose up -d
```

Then open **http://localhost:8900** in your browser.

The file mounts your local `~/.openclaw` workspace into the container so the dashboard
can read logs, sessions, memory files, and metrics.
Uncomment the `environment` entries to customize the instance further:

| Variable | Description |
|---|---|
| `OPENCLAW_DATA_DIR` | Explicit path to the OpenClaw data directory inside the container |
| `OPENCLAW_USER` | Your name shown in the Flow tab |
| `MC_URL` | Mission Control URL (disabled by default) |

Full `docker-compose.yml`:

```yaml
services:
  clawmetry:
    image: stritti/clawmetry:latest
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

### Available tags

The same tags are published to both registries:

- `latest` — latest clawmetry release
- `x.y.z` — specific clawmetry version (e.g. `0.9.0`)

**Docker Hub:** `stritti/clawmetry:<tag>`

**GHCR:** `ghcr.io/stritti/clawmetry-docker:<tag>`

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 -v ~/.openclaw:/root/.openclaw clawmetry-docker
```

## Automatic updates

A GitHub Actions workflow runs daily to check for and build the latest clawmetry version from PyPI. It also triggers on every push to the `main` branch and can be triggered manually via the GitHub Actions UI.

The workflow publishes images to both Docker Hub and GHCR. It requires the following repository secrets to be configured:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub [access token](https://hub.docker.com/settings/security) with write permission |

