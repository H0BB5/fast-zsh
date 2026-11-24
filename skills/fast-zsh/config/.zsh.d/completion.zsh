# One compinit, one cached dump. Order: fpath first, then compinit, then anything that calls compdef.
fpath=(
  ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions(N-/)
  $HOME/.docker/completions(N-/)
  $fpath
)

autoload -Uz compinit
_zdump=$ZSH_CACHE_DIR/zcompdump
# Full (security-audited) rebuild at most once a day; otherwise trust the cache (-C).
if [[ ! -s $_zdump || -n $_zdump(#qN.mh+24) ]]; then
  compinit -d "$_zdump"
else
  compinit -C -d "$_zdump"
fi
# Byte-compile the dump in the background so the next load is faster.
if [[ -s $_zdump && ( ! -s $_zdump.zwc || $_zdump -nt $_zdump.zwc ) ]]; then
  { zcompile "$_zdump" } &!
fi
unset _zdump

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
