#!/bin/sh
# Start ClawMetry directly using its built-in Waitress production server.
# Written in POSIX sh for maximum compatibility with slim container base images.
#
# Accepts the same flags as the clawmetry CLI:
#   --host / -H and --port / -p are forwarded directly to clawmetry.
#   All other documented flags are translated to the environment variables
#   that ClawMetry already honours (OPENCLAW_DATA_DIR, OPENCLAW_HOME, …).

# Honour clawmetry's own environment-variable overrides so that setting
# OPENCLAW_DASHBOARD_PORT (or OPENCLAW_DASHBOARD_HOST) in docker-compose /
# Cloud Run / Railway without passing CLI flags also works.
HOST="${OPENCLAW_DASHBOARD_HOST:-0.0.0.0}"
PORT="${OPENCLAW_DASHBOARD_PORT:-${PORT:-8900}}"

while [ $# -gt 0 ]; do
    case "$1" in
        --host|-H)
            HOST="$2"; shift 2 ;;
        --port|-p)
            PORT="$2"; shift 2 ;;
        --workspace|-w)
            export OPENCLAW_HOME="$2"; shift 2 ;;
        --data-dir|-d)
            export OPENCLAW_DATA_DIR="$2"; shift 2 ;;
        --log-dir|-l)
            export OPENCLAW_LOG_DIR="$2"; shift 2 ;;
        --sessions-dir|-s)
            export OPENCLAW_SESSIONS_DIR="$2"; shift 2 ;;
        --name|-n)
            export OPENCLAW_USER="$2"; shift 2 ;;
        --mc-url)
            export MC_URL="$2"; shift 2 ;;
        --fleet-api-key)
            export CLAWMETRY_FLEET_KEY="$2"; shift 2 ;;
        --no-debug|--debug)
            # Always start with --no-debug (Waitress); consume any override silently.
            shift ;;
        *)
            echo "Warning: ignoring unknown argument '$1'" >&2
            shift ;;
    esac
done

exec /venv/bin/clawmetry \
    --host "${HOST}" \
    --port "${PORT}" \
    --no-debug
