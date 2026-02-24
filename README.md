# 🦞 ClawMetry dockerizerd 🐋

[![GitHub Stars](https://img.shields.io/github/stars/stritti/clawmetry-docker?style=social)](https://github.com/stritti/clawmetry-docker)
[![ClawMetry version](https://img.shields.io/pypi/v/clawmetry?label=ClawMetry)](https://pypi.org/project/clawmetry/)
[![Docker Pulls](https://img.shields.io/docker/pulls/stritti/clawmetry?label=Docker%20Pulls)](https://hub.docker.com/r/stritti/clawmetry)

Docker Image for [ClawMetry](https://clawmetry.com/) — real-time observability dashboard for [OpenClaw](https://github.com/openclaw/openclaw) AI agents.

The image is built automatically from the latest [ClawMetry PyPI release](https://pypi.org/project/clawmetry/) and published to both [Docker Hub](https://hub.docker.com/r/stritti/clawmetry) and the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker).

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

ClawMetry auto-detects the OpenClaw workspace at `~/.openclaw` (= `/home/clawmetry/.openclaw` inside the container).
Mount your host workspace to that path so the dashboard can read logs, sessions, memory files, and metrics:

```bash
docker run -p 8900:8900 \
  -v ~/.openclaw:/home/clawmetry/.openclaw \
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
  -e OPENCLAW_DATA_DIR=/home/clawmetry/.openclaw \
  -v ~/.openclaw:/home/clawmetry/.openclaw \
  stritti/clawmetry:latest
```

### docker-compose

An example [`docker-compose.yml`](docker-compose.yml) is included in this repository.
It defines two services: the **openclaw-cli** gateway and the **ClawMetry** dashboard.

Before starting the stack for the first time, run the OpenClaw onboarding wizard to
create your initial configuration in `~/.openclaw`:

```bash
docker run --rm -it \
  -v ~/.openclaw:/home/node/.openclaw \
  alpine/openclaw:latest openclaw-cli setup
```

Then start both services with:

```bash
docker compose up -d
```

Then open **http://localhost:8900** in your browser.

#### openclaw-cli service

The `openclaw-cli` service runs the OpenClaw AI agent gateway.

| Setting | Description |
|---|---|
| `image` | `alpine/openclaw:latest` — official OpenClaw image |
| `user` | `1000:1000` — non-root user for security |
| `volumes` | `~/.openclaw:/home/node/.openclaw` — agent workspace (config, memory, sessions, logs) |
| `ports` | `18789:18789` — agent gateway port; remove if not needed outside Docker |
| `restart` | `unless-stopped` — auto-restarts on failure |
| `deploy.resources.limits` | `cpus: 1.0`, `memory: 1G` — cap to prevent runaway processes |

#### ClawMetry service

The `clawmetry` service runs the observability dashboard with read-only access to the OpenClaw workspace; it only reads (and never writes) agent data.

The file mounts your local `~/.openclaw` workspace into the container so the dashboard
can read logs, sessions, memory files, and metrics.
Uncomment the `environment` entries to customize the instance further:

| Variable | CLI equivalent | Description |
|---|---|---|
| `OPENCLAW_HOME` | `--workspace` | Path to the agent workspace directory |
| `OPENCLAW_DATA_DIR` | `--data-dir` | OpenClaw data dir (auto-sets workspace, sessions, crons) |
| `OPENCLAW_LOG_DIR` | `--log-dir` | Directory containing agent log files |
| `OPENCLAW_SESSIONS_DIR` | `--sessions-dir` | Directory containing session `.jsonl` files |
| `OPENCLAW_USER` | `--name` | Your name shown in the Flow tab |
| `MC_URL` | `--mc-url` | Mission Control URL (disabled by default) |
| `CLAWMETRY_FLEET_KEY` | `--fleet-api-key` | API key for multi-node fleet authentication |

### Available tags

The same tags are published to both registries:

- `latest` — latest clawmetry release
- `x.y.z` — specific clawmetry version (e.g. `0.9.0`)

**Docker Hub:** `stritti/clawmetry:<tag>`

**GHCR:** `ghcr.io/stritti/clawmetry-docker:<tag>`

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 -v ~/.openclaw:/home/clawmetry/.openclaw clawmetry-docker
```

## Automatic updates

A GitHub Actions workflow runs daily to check for and build the latest clawmetry version from PyPI. It also triggers on every push to the `main` branch and can be triggered manually via the GitHub Actions UI.

The workflow publishes images to both Docker Hub and GHCR. It requires the following repository secrets to be configured:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub [access token](https://hub.docker.com/settings/security) with write permission |

