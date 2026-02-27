#!/bin/sh
# openclaw.sh — Shell wrapper that forwards openclaw commands to Docker
#
# Usage:
#   ./openclaw.sh <command> [args...]
#
# Examples:
#   ./openclaw.sh status
#   ./openclaw.sh session list
#   ./openclaw.sh dashboard --no-open
#
# Install system-wide (optional):
#   sudo cp openclaw.sh /usr/local/bin/openclaw
#   sudo chmod +x /usr/local/bin/openclaw
#
# Enable shell autocomplete after installation:
#   # Bash:
#   sudo cp openclaw_completion.sh /etc/bash_completion.d/openclaw
#   # Zsh (per-user, add to ~/.zshrc):
#   echo 'source /path/to/openclaw_completion.sh' >> ~/.zshrc
#
# After installation you can call openclaw directly from any directory:
#   openclaw status
#
# Environment variables (override defaults):
#   OPENCLAW_HOME   — host path to the OpenClaw workspace (default: ~/.openclaw)
#   OPENCLAW_IMAGE  — Docker image to use (default: alpine/openclaw:latest)
#   COMPOSE_FILE    — path to your docker-compose.yml (default: docker-compose.yml
#                     in the current directory; used when checking running services)

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-alpine/openclaw:latest}"

# If the openclaw-cli container from the Compose stack is already running,
# exec the command inside that container so it shares the same process space,
# network, and volumes as the live gateway.
# Errors from "docker compose ps" are suppressed so the script falls back
# gracefully when Compose is not available or no stack is running in the
# current directory.  If Docker itself is not installed, the "docker run"
# below will fail with a clear error message from Docker.
if docker compose ps --services --filter "status=running" 2>/dev/null | grep -q "^openclaw-cli$"; then
    # Pass -T when stdout is not a TTY (e.g., CI or piped output) to avoid
    # "the input device is not a TTY" errors from docker compose exec.
    if [ -t 1 ]; then
        exec docker compose exec openclaw-cli node openclaw.mjs "$@"
    else
        exec docker compose exec -T openclaw-cli node openclaw.mjs "$@"
    fi
fi

# Otherwise fall back to a temporary one-off container with the same workspace
# volume mount.  The container is removed automatically after the command exits.
docker_run_opts="--rm"

# Only allocate stdin/stdout TTYs when appropriate to avoid failures in
# non-interactive environments (e.g., CI, piped output).
if [ -t 0 ]; then
    docker_run_opts="$docker_run_opts -i"
fi
if [ -t 1 ]; then
    docker_run_opts="$docker_run_opts -t"
fi

exec docker run $docker_run_opts \
    -v "$OPENCLAW_HOME:/home/node/.openclaw" \
    "$OPENCLAW_IMAGE" node openclaw.mjs "$@"
