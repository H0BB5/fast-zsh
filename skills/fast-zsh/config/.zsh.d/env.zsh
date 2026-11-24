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

# zoxide: never record agent-managed git worktrees, so `z myrepo` lands on the main checkout.
# Colon-separated globs; $HOME is zoxide's default. If your team names worktrees <repo>-wt-<name>,
# add *-wt-* to the list in ~/.zsh.local.
export _ZO_EXCLUDE_DIRS="$HOME:$HOME/.cursor/worktrees/*:$HOME/.claude/worktrees/*"
