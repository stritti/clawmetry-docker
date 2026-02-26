# openclaw_completion.sh — Shell completion for the openclaw wrapper
#
# Provides native tab-completion in Bash (via complete/compgen) and
# Zsh (via compdef/_describe).  The correct branch activates automatically
# based on the shell that sources this file.
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
# Zsh (per-user, add to ~/.zshrc):
#   source /path/to/openclaw_completion.sh
#
# Zsh (system-wide, add to a system-wide config, e.g. /etc/zsh/zshrc):
#   source /usr/local/share/openclaw_completion.sh

# ── Subcommands and their options ────────────────────────────────────────────
_OPENCLAW_SUBCOMMANDS="setup status session dashboard"
_OPENCLAW_SESSION_SUBCMDS="list show export"
_OPENCLAW_DASHBOARD_FLAGS="--no-open"

# ── Zsh native completion ─────────────────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then
    _openclaw() {
        local state
        _arguments \
            '1: :->subcmd' \
            '*: :->args'

        case $state in
            subcmd)
                local -a subcmds
                subcmds=(
                    'setup:Run the interactive onboarding wizard'
                    'status:Show gateway status'
                    'session:Manage session recordings'
                    'dashboard:Open or print the Control UI URL'
                )
                _describe 'subcommand' subcmds
                ;;
            args)
                case ${words[2]} in
                    session)
                        local -a session_cmds
                        session_cmds=(
                            'list:List session recordings'
                            'show:Show a session recording'
                            'export:Export a session recording'
                        )
                        _describe 'session subcommand' session_cmds
                        ;;
                    dashboard)
                        _arguments '--no-open[Print URL without opening a browser]'
                        ;;
                esac
                ;;
        esac
    }
    compdef _openclaw openclaw
    return 0
fi

# ── Bash native completion ────────────────────────────────────────────────────
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
# Only attempt registration when Bash (or a shell providing `complete`) is active.
if [ -n "$BASH_VERSION" ] || command -v complete >/dev/null 2>&1; then
    complete -F _openclaw_complete openclaw
fi
