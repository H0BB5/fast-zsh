# `<tool> init zsh` forks and parses on every shell start. Cache its output and only
# regenerate when the binary changes (brew upgrade bumps its mtime).
#   usage: _cached_init <cache-name> <binary> <full init command...>
_cached_init() {
  local name=$1 bin=${commands[$2]} cache=$ZSH_CACHE_DIR/$1.zsh
  shift 2                                  # leaves just the init command, e.g. `starship init zsh`
  [[ -n $bin ]] || return 1
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    if "$@" >| "$cache" 2>/dev/null && [[ -s $cache ]]; then
      zcompile "$cache"
    else
      rm -f "$cache" "$cache.zwc"          # never keep a broken or empty cache
      return 1
    fi
  fi
  source "$cache"
}

_cached_init mise     mise     mise activate zsh              # node & friends, reads .nvmrc / mise.toml
_cached_init fzf      fzf      fzf --zsh                      # Ctrl-R history, Ctrl-T files, Alt-C cd
_cached_init zoxide   zoxide   zoxide init zsh                # `z foo`, `zi`
_cached_init starship starship starship init zsh --print-full-init

[[ -s $HOME/.bun/_bun ]] && source "$HOME/.bun/_bun"          # bun completions (needs compdef)
unfunction _cached_init
