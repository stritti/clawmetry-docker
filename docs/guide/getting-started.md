# Getting Started

## Quickstart

Pull and run the latest image in a single command:

```bash
docker run -p 8900:8900 ghcr.io/stritti/clawmetry-docker:latest
```

Then open **http://localhost:8900** in your browser.

## Mount your OpenClaw workspace (recommended)

Clawmetry auto-detects the OpenClaw workspace at `~/.openclaw` (`/root/.openclaw` inside the container).
Mount your host workspace so the dashboard can read logs, sessions, memory files, and metrics:

```bash
docker run -p 8900:8900 \
  -v ~/.openclaw:/root/.openclaw \
  ghcr.io/stritti/clawmetry-docker:latest
```

Or pass a custom path explicitly:

```bash
docker run -p 8900:8900 \
  -v /path/to/workspace:/data \
  ghcr.io/stritti/clawmetry-docker:latest --data-dir /data
```

## Available tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest clawmetry release |
| `x.y.z` | Specific clawmetry version (e.g. `0.9.0`) |

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 -v ~/.openclaw:/root/.openclaw clawmetry-docker
```
