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

#### Shell wrapper for openclaw

The included [`openclaw.sh`](openclaw.sh) wrapper lets you call any `openclaw` subcommand directly from your Linux/macOS shell — no need to type the full `docker` invocation each time.

**How it works:**
- If the Compose stack is running (`docker compose up`), the wrapper executes the command inside the live `openclaw-cli` container via `docker compose exec`.
- Otherwise it spins up a temporary container (`docker run --rm -it`) with your `~/.openclaw` workspace mounted.

**Quick start (one-time install):**

```bash
sudo cp openclaw.sh /usr/local/bin/openclaw
sudo chmod +x /usr/local/bin/openclaw
```

**Enable shell autocomplete** (optional, requires the included [`openclaw_completion.sh`](openclaw_completion.sh)):

```bash
# Bash (system-wide — open a new shell afterwards):
sudo cp openclaw_completion.sh /etc/bash_completion.d/openclaw

# Bash (per-user — add to ~/.bashrc):
echo 'source /path/to/openclaw_completion.sh' >> ~/.bashrc

# Zsh (system-wide — open a new shell afterwards):
sudo cp openclaw_completion.sh /usr/local/share/zsh/site-functions/_openclaw

# Zsh (per-user via bashcompinit — add to ~/.zshrc):
echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zshrc
echo 'source /path/to/openclaw_completion.sh' >> ~/.zshrc
```

After enabling autocomplete, press **Tab** after `openclaw` to complete subcommands and flags:

```
openclaw <Tab>          → setup  status  session  dashboard
openclaw session <Tab>  → list  show  export
openclaw dashboard <Tab> → --no-open
```

**Usage examples:**

```bash
# Run the interactive onboarding wizard
openclaw setup

# Show gateway status
openclaw status

# List session recordings
openclaw session list

# Open the Control UI (print URL without opening a browser)
openclaw dashboard --no-open
```

**Override defaults with environment variables:**

| Variable | Default | Description |
|---|---|---|
| `OPENCLAW_HOME` | `~/.openclaw` | Host path to the OpenClaw workspace |
| `OPENCLAW_IMAGE` | `alpine/openclaw:latest` | Docker image used for one-off containers |

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

