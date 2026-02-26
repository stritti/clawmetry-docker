#!/bin/sh
# openclaw-cli.sh — Shell wrapper that forwards openclaw-cli commands to Docker
#
# Usage:
#   ./openclaw-cli.sh <command> [args...]
#
# Examples:
#   ./openclaw-cli.sh status
#   ./openclaw-cli.sh session list
#   ./openclaw-cli.sh dashboard --no-open
#
# Install system-wide (optional):
#   sudo cp openclaw-cli.sh /usr/local/bin/openclaw-cli
#   sudo chmod +x /usr/local/bin/openclaw-cli
#
# After installation you can call openclaw-cli directly from any directory:
#   openclaw-cli status
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
    exec docker compose exec openclaw-cli openclaw-cli "$@"
fi

# Otherwise fall back to a temporary one-off container with the same workspace
# volume mount.  The container is removed automatically after the command exits.
exec docker run --rm -it \
    -v "$OPENCLAW_HOME:/home/node/.openclaw" \
    "$OPENCLAW_IMAGE" openclaw-cli "$@"
