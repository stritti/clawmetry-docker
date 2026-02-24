# Docker Compose

An example [`docker-compose.yml`](https://github.com/stritti/clawmetry-docker/blob/main/docker-compose.yml) is included in the repository.
It defines two services: the **openclaw-cli** gateway and the **[ClawMetry](https://clawmetry.com/)** dashboard.

## First-time setup

Before starting the stack for the first time, run the OpenClaw onboarding wizard
to create your initial configuration in `~/.openclaw`:

```bash
docker run --rm -it \
  -v ~/.openclaw:/home/node/.openclaw \
  alpine/openclaw:latest openclaw-cli setup
```

The wizard asks you to choose an AI model, select a messaging channel, and generate a gateway token.

## Start the stack

```bash
docker compose up -d
```

Then open **http://localhost:8900** in your browser.

## openclaw-cli service

The `openclaw-cli` service runs the OpenClaw AI agent gateway.

### Settings reference

| Setting | Value | Description |
|---|---|---|
| `image` | `alpine/openclaw:latest` | Official OpenClaw Docker image (Alpine-based, minimal footprint). Pin to a version tag (e.g. `1.2.3`) for reproducible deployments. |
| `user` | `1000:1000` | Runs as non-root user for security. If `~/.openclaw` is owned by a different UID, run `sudo chown -R 1000:1000 ~/.openclaw` first. |
| `volumes` | `~/.openclaw:/home/node/.openclaw` | Persists the full OpenClaw workspace on the host — config, memory files, session recordings, and logs. Shared with the ClawMetry dashboard below. |
| `ports` | `18789:18789` | OpenClaw gateway listens on port 18789 for connected AI agent clients. Remove if not needed outside Docker (e.g. when routing through a reverse proxy). |
| `restart` | `unless-stopped` | Container restarts automatically after crashes or host reboots, but stays stopped if you `docker compose stop` it manually. |
| `deploy.resources.limits.cpus` | `1.0` | Maximum CPU share. Increase if your workload requires more parallelism. |
| `deploy.resources.limits.memory` | `1G` | Hard memory cap. Adjust to match your available RAM. |

### docker-compose.yml (openclaw-cli section)

```yaml
  openclaw-cli:
    image: alpine/openclaw:latest
    user: "1000:1000"
    volumes:
      - ~/.openclaw:/home/node/.openclaw
    ports:
      - "18789:18789"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1G
```

## ClawMetry dashboard service

The `clawmetry` service runs the observability dashboard.

The file mounts your local `~/.openclaw` workspace into the container so the [ClawMetry](https://clawmetry.com/) dashboard
can read logs, sessions, memory files, and metrics.
Uncomment the `environment` entries to customize the instance further.

## Environment variables in docker-compose

All environment variables supported by [ClawMetry](https://clawmetry.com/) can be used in your `docker-compose.yml`:

| Variable | CLI equivalent | Description |
|---|---|---|
| `OPENCLAW_HOME` | `--workspace` | Path to the agent workspace directory |
| `OPENCLAW_DATA_DIR` | `--data-dir` | OpenClaw data dir (auto-sets workspace, sessions, crons) |
| `OPENCLAW_LOG_DIR` | `--log-dir` | Directory containing agent log files |
| `OPENCLAW_SESSIONS_DIR` | `--sessions-dir` | Directory containing session `.jsonl` files |
| `OPENCLAW_USER` | `--name` | Your name shown in the Flow tab |
| `MC_URL` | `--mc-url` | Mission Control URL (disabled by default) |
| `CLAWMETRY_FLEET_KEY` | `--fleet-api-key` | API key for multi-node fleet authentication |

For detailed descriptions of each variable, see the [Configuration reference](/guide/configuration).

## Full docker-compose.yml

```yaml
services:

  # ─── openclaw-cli ─────────────────────────────────────────────────────────
  openclaw-cli:
    image: alpine/openclaw:latest
    user: "1000:1000"
    volumes:
      - ~/.openclaw:/home/node/.openclaw
    ports:
      - "18789:18789"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1G

  # ─── ClawMetry dashboard ───────────────────────────────────────────────────
  clawmetry:
    image: stritti/clawmetry:latest
    ports:
      - "8900:8900"
    volumes:
      - ~/.openclaw:/home/clawmetry/.openclaw
    environment:
      # Optional: explicitly set the OpenClaw data directory
      # OPENCLAW_DATA_DIR: /home/clawmetry/.openclaw
      # Optional: show your name in the Flow tab
      # OPENCLAW_USER: "Your Name"
      # Optional: Mission Control URL
      # MC_URL: "https://your-mission-control"
      # Optional: API key for multi-node fleet authentication
      # CLAWMETRY_FLEET_KEY: "your-api-key"
    restart: unless-stopped
```

> **Alternative:** You can also use the image from the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker):
> `image: ghcr.io/stritti/clawmetry-docker:latest`
