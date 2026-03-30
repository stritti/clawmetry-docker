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
| `OPENCLAW_DASHBOARD_HOST` | `--host` | Bind address (default: `0.0.0.0`) |
| `OPENCLAW_DASHBOARD_PORT` | `--port` | Listening port (default: `8900`) |

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

#### `OPENCLAW_DASHBOARD_HOST` — `--host`

Network interface address the server binds to. The default (`0.0.0.0`) listens on all interfaces, which is required inside a container. Override this only if you need to restrict the bind address.

```bash
-e OPENCLAW_DASHBOARD_HOST="0.0.0.0"
```

#### `OPENCLAW_DASHBOARD_PORT` — `--port`

TCP port the server listens on. Defaults to `8900`. Use this when port `8900` is already taken on the host or when the cloud platform assigns a port dynamically via its own `PORT` environment variable.

```bash
-e OPENCLAW_DASHBOARD_PORT="9000"
```

## Example

```bash
docker run -p 8900:8900 \
  -e OPENCLAW_DATA_DIR=/home/clawmetry/.openclaw \
  -v ~/.openclaw:/home/clawmetry/.openclaw \
  stritti/clawmetry:latest
```
