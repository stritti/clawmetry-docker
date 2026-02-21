# Getting Started

## Quickstart

Pull and run the latest [ClawMetry](https://clawmetry.com/) image in a single command:

```bash
docker run -p 8900:8900 stritti/clawmetry:latest
```

Then open **http://localhost:8900** in your browser.

## Mount your OpenClaw workspace (recommended)

[ClawMetry](https://clawmetry.com/) auto-detects the OpenClaw workspace at `~/.openclaw` (`/root/.openclaw` inside the container).
Mount your host workspace so the dashboard can read logs, sessions, memory files, and metrics:

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

## Available tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest clawmetry release |
| `x.y.z` | Specific clawmetry version (e.g. `0.9.0`) |

Images are published to [Docker Hub](https://hub.docker.com/r/stritti/clawmetry) (`stritti/clawmetry:<tag>`).
As an alternative, images are also available from the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker) (`ghcr.io/stritti/clawmetry-docker:<tag>`).

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 -v ~/.openclaw:/root/.openclaw clawmetry-docker
```
