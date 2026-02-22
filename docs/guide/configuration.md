# Configuration

[ClawMetry](https://clawmetry.com/) can be configured either via CLI flags passed to the container command or via environment variables.

## Environment variables

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

### Variable details

#### `OPENCLAW_HOME` — `--workspace`

The root workspace directory used by the [OpenClaw](https://github.com/openclaw/openclaw) agent.
Defaults to `~/.openclaw` (= `/home/clawmetry/.openclaw` inside the container).
When no other directory variables are set, log, session, and cron paths are derived from this location.

```bash
-e OPENCLAW_HOME=/home/clawmetry/.openclaw
```

#### `OPENCLAW_DATA_DIR` — `--data-dir`

Convenience variable that sets the OpenClaw data directory and **automatically configures** the workspace, sessions, and crons sub-paths in one step.
Use this instead of setting each directory individually when all your data lives under a single root.

```bash
-e OPENCLAW_DATA_DIR=/home/clawmetry/.openclaw
```

#### `OPENCLAW_LOG_DIR` — `--log-dir`

Directory where the OpenClaw agent writes its log files.
Override this when your logs are stored in a location separate from the main workspace (e.g. a dedicated log volume).

```bash
-e OPENCLAW_LOG_DIR=/home/clawmetry/.openclaw/logs
```

#### `OPENCLAW_SESSIONS_DIR` — `--sessions-dir`

Directory that contains the session recording files (`.jsonl` format).
Each session is stored as a separate `.jsonl` file and is read by [ClawMetry](https://clawmetry.com/) to populate the Sessions and Flow views.

```bash
-e OPENCLAW_SESSIONS_DIR=/home/clawmetry/.openclaw/sessions
```

#### `OPENCLAW_USER` — `--name`

Your display name shown in the **Flow** tab of the [ClawMetry](https://clawmetry.com/) dashboard.
Useful when multiple users share the same workspace or fleet.

```bash
-e OPENCLAW_USER="Alice"
```

#### `MC_URL` — `--mc-url`

URL of the Mission Control server.
Mission Control is disabled by default; set this variable to connect [ClawMetry](https://clawmetry.com/) to a running Mission Control instance for centralized fleet oversight.

```bash
-e MC_URL="https://your-mission-control"
```

#### `CLAWMETRY_FLEET_KEY` — `--fleet-api-key`

API key used to authenticate this node against a multi-node fleet.
Required when running [ClawMetry](https://clawmetry.com/) in a distributed setup where multiple agents report to a shared Mission Control.

```bash
-e CLAWMETRY_FLEET_KEY="your-api-key"
```

## Example

```bash
docker run -p 8900:8900 \
  -e OPENCLAW_DATA_DIR=/home/clawmetry/.openclaw \
  -v ~/.openclaw:/home/clawmetry/.openclaw \
  stritti/clawmetry:latest
```
