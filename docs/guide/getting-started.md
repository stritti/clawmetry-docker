# Getting Started

## Quickstart

Pull and run the latest [ClawMetry](https://clawmetry.com/) image in a single command:

```bash
docker run -p 8900:8900 stritti/clawmetry:latest
```

Then open **http://localhost:8900** in your browser.

## Mount your agent workspaces (recommended)

[ClawMetry](https://clawmetry.com/) auto-detects the workspaces of 32 AI agent runtimes. OpenClaw lives at `~/.openclaw` (`/home/clawmetry/.openclaw` inside the container).
Mount the directories for whichever runtimes you use so the dashboard can read logs, sessions, memory files, and metrics. Nothing is written back, so `:ro` is safe:

| Runtime | Host directory |
|---|---|
| OpenClaw | `~/.openclaw` |
| Claude Code | `~/.claude` |
| OpenAI Codex | `~/.codex` |
| Gemini CLI | `~/.gemini` |
| Aider | `~/.aider` |
| GitHub Copilot | `~/.copilot` |

These are the most common host directories — ClawMetry supports 32 runtimes in total ([full list](https://github.com/vivekchand/clawmetry/blob/main/SUPPORTED_RUNTIMES.txt) upstream). Four of them (OpenClaw, NemoClaw, Goose, Qwen Code) are read by the open-source package alone; the remaining 28 require the paid `clawmetry-pro` companion ([entitlements](https://github.com/vivekchand/clawmetry/blob/main/docs/ENTITLEMENTS.md)).

```bash
docker run -p 8900:8900 \
  -v ~/.openclaw:/home/clawmetry/.openclaw:ro \
  stritti/clawmetry:latest
```

Mount additional runtimes as needed:

```bash
docker run -p 8900:8900 \
  -v ~/.openclaw:/home/clawmetry/.openclaw:ro \
  -v ~/.claude:/home/clawmetry/.claude:ro \
  -v ~/.codex:/home/clawmetry/.codex:ro \
  stritti/clawmetry:latest
```

Or pass a custom path explicitly:

```bash
docker run -p 8900:8900 \
  -v /path/to/workspace:/data \
  stritti/clawmetry:latest --data-dir /data
```

## Available tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest clawmetry release |
| `x.y.z` | Specific clawmetry version (e.g. `0.12.942`) |

Images are published to [Docker Hub](https://hub.docker.com/r/stritti/clawmetry) (`stritti/clawmetry:<tag>`).
As an alternative, images are also available from the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker) (`ghcr.io/stritti/clawmetry-docker:<tag>`).

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 -v ~/.openclaw:/home/clawmetry/.openclaw:ro clawmetry-docker
```

## Deploy to the cloud

See the [Cloud Deployment guide](/guide/cloud-deployment) for instructions on running ClawMetry on a VPS, Google Cloud Run, Railway, Fly.io, or in OTLP-only mode.
