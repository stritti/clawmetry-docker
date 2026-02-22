# Docker Compose

An example [`docker-compose.yml`](https://github.com/stritti/clawmetry-docker/blob/main/docker-compose.yml) is included in the repository.
Copy it to your project and start the service:

```bash
docker compose up -d
```

Then open **http://localhost:8900** in your browser.

The file mounts your local `~/.openclaw` workspace into the container so the [ClawMetry](https://clawmetry.com/) dashboard
can read logs, sessions, memory files, and metrics.
Uncomment the `environment` entries to customize the instance further.

## docker-compose.yml

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
      - ~/.openclaw:/home/clawmetry/.openclaw
    environment:
      # Optional: explicitly set the OpenClaw data directory
      # OPENCLAW_DATA_DIR: /home/clawmetry/.openclaw
      # Optional: show your name in the Flow tab
      # OPENCLAW_USER: "Your Name"
      # Optional: Mission Control URL
      # MC_URL: "https://your-mission-control"
    restart: unless-stopped
```

> **Alternative:** You can also use the image from the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker):
> `image: ghcr.io/stritti/clawmetry-docker:latest`

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
