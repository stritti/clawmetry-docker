#!/bin/sh
# install.sh — One-line installer for the openclaw shell wrapper and autocomplete
#
# Run directly from the internet:
#   curl -fsSL https://raw.githubusercontent.com/stritti/clawmetry-docker/main/install.sh | bash
#
# What it installs:
#   1. openclaw.sh   → /usr/local/bin/openclaw  (or ~/.local/bin/openclaw as fallback)
#   2. openclaw_completion.sh → shell-specific location (Bash or Zsh)
#
# Override defaults with environment variables:
#   OPENCLAW_INSTALL_DIR   — directory to install the binary (default: /usr/local/bin)
#   OPENCLAW_REPO          — GitHub repo slug (default: stritti/clawmetry-docker)
#   OPENCLAW_BRANCH        — branch/tag to download from (default: main)

set -e

OPENCLAW_REPO="${OPENCLAW_REPO:-stritti/clawmetry-docker}"
OPENCLAW_BRANCH="${OPENCLAW_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${OPENCLAW_REPO}/${OPENCLAW_BRANCH}"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31mERROR\033[0m %s\n' "$*" >&2; exit 1; }

# Download a URL to a file (supports curl and wget)
download() {
    url="$1"; dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dest" "$url"
    else
        die "Neither curl nor wget found. Install one and re-run."
    fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────

if ! command -v docker >/dev/null 2>&1; then
    warn "Docker is not installed. The openclaw wrapper requires Docker to run."
    warn "Install Docker from https://docs.docker.com/get-docker/ before using openclaw."
fi

# ── Choose install directory ──────────────────────────────────────────────────

if [ -n "$OPENCLAW_INSTALL_DIR" ]; then
    INSTALL_DIR="$OPENCLAW_INSTALL_DIR"
elif [ -w /usr/local/bin ]; then
    INSTALL_DIR="/usr/local/bin"
elif command -v sudo >/dev/null 2>&1; then
    INSTALL_DIR="/usr/local/bin"
    USE_SUDO=1
else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    warn "No write access to /usr/local/bin and sudo not found."
    warn "Installing to $INSTALL_DIR — make sure it is in your PATH."
fi

# ── Install openclaw wrapper ──────────────────────────────────────────────────

info "Downloading openclaw wrapper …"
TMP_WRAPPER="$(mktemp)"
download "${BASE_URL}/openclaw.sh" "$TMP_WRAPPER"
chmod +x "$TMP_WRAPPER"

WRAPPER_DEST="${INSTALL_DIR}/openclaw"
if [ -n "$USE_SUDO" ]; then
    sudo mv "$TMP_WRAPPER" "$WRAPPER_DEST"
    sudo chmod +x "$WRAPPER_DEST"
else
    mv "$TMP_WRAPPER" "$WRAPPER_DEST"
fi
ok "Installed wrapper → $WRAPPER_DEST"

# ── Install shell completion ──────────────────────────────────────────────────

info "Downloading shell completion script …"
TMP_COMP="$(mktemp)"
download "${BASE_URL}/openclaw_completion.sh" "$TMP_COMP"

# Detect the current shell from the parent process
DETECTED_SHELL="$(basename "${SHELL:-sh}")"

case "$DETECTED_SHELL" in
    zsh)
        # Per-user Zsh install: copy to ~/.local/share and source from ~/.zshrc
        COMP_DEST="$HOME/.local/share/openclaw_completion.sh"
        mkdir -p "$(dirname "$COMP_DEST")"
        cp "$TMP_COMP" "$COMP_DEST"
        if ! grep -qF "openclaw_completion.sh" "$HOME/.zshrc" 2>/dev/null; then
            printf '\n# openclaw shell completion\nsource %s\n' "$COMP_DEST" >> "$HOME/.zshrc"
            ok "Added completion source line to ~/.zshrc"
        else
            ok "Completion already sourced in ~/.zshrc — skipped"
        fi
        ok "Installed completion → $COMP_DEST"
        ;;
    bash)
        # Try system-wide Bash completion directory first, then per-user fallback
        if [ -d /etc/bash_completion.d ] && { [ -w /etc/bash_completion.d ] || [ -n "$USE_SUDO" ]; }; then
            COMP_DEST="/etc/bash_completion.d/openclaw"
            if [ -n "$USE_SUDO" ]; then
                sudo mv "$TMP_COMP" "$COMP_DEST"
            else
                mv "$TMP_COMP" "$COMP_DEST"
            fi
            ok "Installed completion → $COMP_DEST (open a new shell to activate)"
        else
            # Per-user fallback: source from ~/.bashrc
            COMP_DEST="$HOME/.local/share/openclaw_completion.sh"
            mkdir -p "$(dirname "$COMP_DEST")"
            cp "$TMP_COMP" "$COMP_DEST"
            if ! grep -qF "openclaw_completion.sh" "$HOME/.bashrc" 2>/dev/null; then
                printf '\n# openclaw shell completion\nsource %s\n' "$COMP_DEST" >> "$HOME/.bashrc"
                ok "Added completion source line to ~/.bashrc"
            else
                ok "Completion already sourced in ~/.bashrc — skipped"
            fi
            ok "Installed completion → $COMP_DEST"
        fi
        ;;
    *)
        # Unknown shell: install to ~/.local/share and print instructions
        COMP_DEST="$HOME/.local/share/openclaw_completion.sh"
        mkdir -p "$(dirname "$COMP_DEST")"
        cp "$TMP_COMP" "$COMP_DEST"
        ok "Installed completion → $COMP_DEST"
        warn "Unknown shell '$DETECTED_SHELL'. Add the following line to your shell RC file to enable completion:"
        warn "  source $COMP_DEST"
        ;;
esac

rm -f "$TMP_COMP"

# ── Done ──────────────────────────────────────────────────────────────────────

printf '\n'
info "Installation complete!"
printf '\n'
printf '  Run the onboarding wizard:\n'
printf '    openclaw setup\n'
printf '\n'
printf '  Check gateway status:\n'
printf '    openclaw status\n'
printf '\n'
if [ -n "$USE_SUDO" ] || [ "$INSTALL_DIR" != "$HOME/.local/bin" ]; then
    printf '  Reload your shell or open a new terminal to use the openclaw command.\n'
else
    printf '  Make sure %s is in your PATH, then reload your shell.\n' "$INSTALL_DIR"
fi
printf '\n'
