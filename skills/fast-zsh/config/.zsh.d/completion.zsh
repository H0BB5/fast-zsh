# One compinit, one cached dump. Order: fpath first, then compinit, then anything that calls compdef.
fpath=(
  ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions(N-/)
  $HOME/.docker/completions(N-/)
  $fpath
)

# Anonymous function so EXTENDED_GLOB (needed for the (#q...) age test) stays local and never
# leaks into the interactive shell, where it breaks `git reset HEAD^`.
() {
  setopt local_options extended_glob
  autoload -Uz compinit
  local zdump=$ZSH_CACHE_DIR/zcompdump
  # Full (security-audited) pass at most once a day; otherwise trust the cache (-C, ~12ms faster).
  # compinit leaves a still-valid dump untouched, so without the `touch` an old dump would send
  # every later shell through the slow audit again.
  if [[ ! -s $zdump || -n $zdump(#qN.mh+24) ]]; then
    compinit -d "$zdump" && touch "$zdump"
  else
    compinit -C -d "$zdump"
  fi
  # Byte-compile the dump in the background so the next load is faster.
  if [[ -s $zdump && ( ! -s $zdump.zwc || $zdump -nt $zdump.zwc ) ]]; then
    { zcompile "$zdump" } &!
  fi
}

zmodload zsh/complist
_comp_options+=(globdots)                       # complete dotfiles without GLOB_DOTS
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"
zstyle ':completion:*' squeeze-slashes yes
zstyle ':completion:*:descriptions' format '%F{8}── %d ──%f'
zstyle ':completion:*' group-name ''
bindkey -M menuselect '^[[Z' reverse-menu-complete
