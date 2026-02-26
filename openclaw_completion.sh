# openclaw_completion.sh — Shell completion for the openclaw wrapper
#
# Provides tab-completion for the `openclaw` command in both Bash and Zsh.
#
# Installation
# ────────────
# Bash (system-wide, requires bash-completion package):
#   sudo cp openclaw_completion.sh /etc/bash_completion.d/openclaw
#   # Then open a new shell or run: source /etc/bash_completion.d/openclaw
#
# Bash (per-user, add to ~/.bashrc):
#   source /path/to/openclaw_completion.sh
#
# Zsh (system-wide):
#   sudo cp openclaw_completion.sh /usr/local/share/zsh/site-functions/_openclaw
#   # Then open a new shell or run: autoload -U compinit && compinit
#
# Zsh (per-user via bashcompinit, add to ~/.zshrc):
#   autoload -U +X bashcompinit && bashcompinit
#   source /path/to/openclaw_completion.sh

# ── Subcommands and their options ────────────────────────────────────────────
_OPENCLAW_SUBCOMMANDS="setup status session dashboard"
_OPENCLAW_SESSION_SUBCMDS="list show export"
_OPENCLAW_DASHBOARD_FLAGS="--no-open"

# ── Bash completion function ──────────────────────────────────────────────────
_openclaw_complete() {
    local cur prev words cword
    # Use _init_completion if available (bash-completion ≥ 2.x), fall back otherwise
    if declare -f _init_completion > /dev/null 2>&1; then
        _init_completion || return
    else
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    case "$cword" in
        1)
            # Complete the primary subcommand
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$_OPENCLAW_SUBCOMMANDS" -- "$cur") )
            ;;
        2)
            case "$prev" in
                session)
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "$_OPENCLAW_SESSION_SUBCMDS" -- "$cur") )
                    ;;
                dashboard)
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "$_OPENCLAW_DASHBOARD_FLAGS" -- "$cur") )
                    ;;
            esac
            ;;
    esac
}

# Register the completion function for the `openclaw` command
complete -F _openclaw_complete openclaw
