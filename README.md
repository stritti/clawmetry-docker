# clawmetry-docker

Docker Image for [clawmetry](https://clawmetry.com/) — real-time observability dashboard for [OpenClaw](https://github.com/openclaw/openclaw) AI agents.

The image is built automatically from the latest [clawmetry PyPI release](https://pypi.org/project/clawmetry/) and published to the [GitHub Container Registry](https://github.com/stritti/clawmetry-docker/pkgs/container/clawmetry-docker).

## Usage

```bash
docker run -p 8900:8900 ghcr.io/stritti/clawmetry-docker:latest
```

Then open **http://localhost:8900** in your browser.

### Mount your OpenClaw workspace

```bash
docker run -p 8900:8900 \
  -v /path/to/your/workspace:/workspace \
  ghcr.io/stritti/clawmetry-docker:latest --workspace /workspace
```

### Available tags

- `latest` — latest clawmetry release
- `x.y.z` — specific clawmetry version (e.g. `0.9.0`)

## Build locally

```bash
docker build -t clawmetry-docker .
docker run -p 8900:8900 clawmetry-docker
```

## Automatic updates

A GitHub Actions workflow runs daily to check for and build the latest clawmetry version from PyPI. It also triggers on every push to the `main` branch and can be triggered manually via the GitHub Actions UI.
