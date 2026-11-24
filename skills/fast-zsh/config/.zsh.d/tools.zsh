# `<tool> init zsh` forks and parses on every shell start, so its output is cached.
#
# Invalidation: Homebrew keeps each binary's build date, so a freshly upgraded tool can look
# older than its cache. The resolved path (.../Cellar/<tool>/<version>/bin/<tool>) changes with
# every version, so the cache records it in a sidecar file and rebuilds when it differs.
# The mtime check stays for tools updated in place (for example mise installed with its script).
#
#   usage: _cached_init <cache-name> <binary> <full init command...>
_cached_init() {
  local name=$1 bin=${commands[$2]} cache=$ZSH_CACHE_DIR/$1.zsh
  shift 2                                  # leaves just the init command, e.g. `starship init zsh`
  [[ -n $bin ]] || return 1
  local real=${bin:A}
  if [[ ! -s $cache || ! -r $cache.src || $bin -nt $cache || "$(<$cache.src)" != $real ]]; then
    if "$@" >| "$cache" 2>/dev/null && [[ -s $cache ]]; then
      print -r -- $real >| "$cache.src"
      zcompile "$cache"
    else
      rm -f "$cache" "$cache.zwc" "$cache.src"   # never keep a broken or empty cache
      return 1
    fi
  fi
  source "$cache"
}

# mise's default mode runs `mise hook-env` before every prompt (about 12ms) so PATH and [env]
# follow your config files. To trade that for shims (no per-prompt cost, but no [env] support
# and one extra exec per command), put `export FAST_ZSH_MISE_SHIMS=1` in ~/.zshenv.
if [[ -n $FAST_ZSH_MISE_SHIMS ]]; then
  path=(${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims $path)
else
  _cached_init mise mise mise activate zsh      # node & friends, reads .nvmrc / mise.toml
fi
_cached_init fzf      fzf      fzf --zsh                      # Ctrl-R history, Ctrl-T files, Alt-C cd
_cached_init zoxide   zoxide   zoxide init zsh                # `z foo`, `zi`
_cached_init starship starship starship init zsh --print-full-init

[[ -s $HOME/.bun/_bun ]] && source "$HOME/.bun/_bun"          # bun completions (needs compdef)
unfunction _cached_init
