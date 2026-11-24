# ── Shell options ────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB INTERACTIVE_COMMENTS LONG_LIST_JOBS COMBINING_CHARS
setopt NO_BEEP NO_FLOW_CONTROL
# Deliberately NOT set: GLOB_DOTS (makes `rm -rf *` delete .git etc.) and MENU_COMPLETE
# (cycles through matches instead of showing the menu). Dotfile *completion* is enabled
# in completion.zsh instead.

# ── History ──────────────────────────────────────────────────────
HISTFILE=$HOME/.zsh_history
HISTSIZE=200000
SAVEHIST=200000
setopt EXTENDED_HISTORY SHARE_HISTORY          # SHARE_HISTORY implies incremental append
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

# ── Keys ─────────────────────────────────────────────────────────
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search   '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search
bindkey '^[[1;3D' backward-word '^[[1;3C' forward-word      # Option+arrows
bindkey '^[[1;5D' backward-word '^[[1;5C' forward-word      # Ctrl+arrows
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word                             # Ctrl+Backspace
bindkey '^X^E' edit-command-line                            # edit the line in $EDITOR
