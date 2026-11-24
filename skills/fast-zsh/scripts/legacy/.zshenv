# Read by EVERY zsh (scripts, IDE tasks, subshells). Keep tiny and side-effect free.

# Stop macOS writing a full history copy per terminal tab to ~/.zsh_sessions/
export SHELL_SESSIONS_DISABLE=1

[[ -r $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
