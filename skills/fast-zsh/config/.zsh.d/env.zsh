# Respect an editor that is already set; otherwise prefer nvim, then vim.
if (( $+commands[nvim] )); then
  export EDITOR=${EDITOR:-nvim}
else
  export EDITOR=${EDITOR:-vim}
fi
export VISUAL=${VISUAL:-$EDITOR}
export COLORTERM=truecolor

# fzf: use fd (fast, respects .gitignore) instead of find
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'

# fzf previews. Ctrl-/ toggles the preview pane.
if (( $+commands[bat] )); then      # Ctrl-T: file contents
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :200 {}' --preview-window=right:55%:wrap --bind 'ctrl-/:toggle-preview'"
fi
if (( $+commands[eza] )); then      # Alt-C: directory tree
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} | head -60' --bind 'ctrl-/:toggle-preview'"
fi
# Ctrl-R: full command in a hidden pane, for long commands that get cut off
export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=up:3:hidden:wrap --bind 'ctrl-/:toggle-preview'"

# zoxide: never record worktrees or scratch directories, so `z myrepo` lands on the real checkout.
# Colon-separated globs, and `*` crosses slashes. Claude Code creates worktrees inside each repo at
# <repo>/.claude/worktrees/, Cursor uses ~/.cursor/worktrees/, and many teams keep <repo>/.worktrees/.
# If yours are named <repo>-wt-<name>, add *-wt-* to the list in ~/.zsh.local.
export _ZO_EXCLUDE_DIRS="$HOME:*/.claude/worktrees/*:*/.cursor/worktrees/*:*/.worktrees/*:/tmp/*:/private/tmp/*:/private/var/folders/*"
