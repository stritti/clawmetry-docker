#!/bin/sh
# Start ClawMetry using gunicorn (production WSGI server) instead of
# Flask's built-in development server.  Written in POSIX sh for maximum
# compatibility with slim container base images.
#
# Accepts the same flags as the clawmetry CLI:
#   --host / -H and --port / -p are forwarded to gunicorn's --bind.
#   All other documented flags are translated to the environment variables
#   that ClawMetry already honours (OPENCLAW_DATA_DIR, OPENCLAW_HOME, …).

HOST="0.0.0.0"
PORT="8900"

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
        --fleet-db-path)
            export FLEET_DB_PATH="$2"; shift 2 ;;
        --no-debug|--debug)
            # Debug mode is not applicable under gunicorn; silently ignore.
            shift ;;
        *)
            echo "Warning: ignoring unknown argument '$1'" >&2
            shift ;;
    esac
done

# Ensure HOME is set correctly for the non-root user.
export HOME=/home/clawmetry
export OPENCLAW_HOME="${OPENCLAW_HOME:-/home/clawmetry/.openclaw}"

# The container starts as root. We ensure the data directory exists and
# has the correct permissions before dropping privileges.
DATA_DIR="${OPENCLAW_DATA_DIR:-/home/clawmetry/.openclaw}"
echo "Fixing permissions for $DATA_DIR..."
mkdir -p "$DATA_DIR"
chown -R clawmetry:clawmetry "$DATA_DIR"
ls -ld "$DATA_DIR"
ls -la "$DATA_DIR"

# Also ensure the fleet DB directory exists if FLEET_DB_PATH is set.
if [ -n "$FLEET_DB_PATH" ]; then
    echo "Fixing permissions for fleet DB at $FLEET_DB_PATH..."
    DB_DIR=$(dirname "$FLEET_DB_PATH")
    mkdir -p "$DB_DIR"
    chown -R clawmetry:clawmetry "$DB_DIR"
    ls -ld "$DB_DIR"
fi

echo "Starting gunicorn with gosu clawmetry..."
exec gosu clawmetry /venv/bin/gunicorn \
    --bind "${HOST}:${PORT}" \
    --workers 1 \
    --threads 16 \
    --timeout 120 \
    --capture-output \
    wsgi:app
