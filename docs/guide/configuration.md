# Configuration

All CLI flags can alternatively be set via environment variables.

## Environment variables

| Variable | CLI equivalent | Description |
|---|---|---|
| `OPENCLAW_HOME` | `--workspace` | Path to the agent workspace directory |
| `OPENCLAW_DATA_DIR` | `--data-dir` | OpenClaw data dir (auto-sets workspace, sessions, crons) |
| `OPENCLAW_LOG_DIR` | `--log-dir` | Directory containing agent log files |
| `OPENCLAW_SESSIONS_DIR` | `--sessions-dir` | Directory containing session `.jsonl` files |
| `OPENCLAW_USER` | `--name` | Your name shown in the Flow tab |
| `MC_URL` | `--mc-url` | Mission Control URL (disabled by default) |
| `CLAWMETRY_FLEET_KEY` | `--fleet-api-key` | API key for multi-node fleet authentication |

## Example

```bash
docker run -p 8900:8900 \
  -e OPENCLAW_DATA_DIR=/root/.openclaw \
  -v ~/.openclaw:/root/.openclaw \
  ghcr.io/stritti/clawmetry-docker:latest
```
