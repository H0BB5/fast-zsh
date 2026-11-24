# `typeset -U` keeps each array free of duplicates, however many times PATH is prepended.
typeset -U path fpath manpath

# Non-login shells (some IDE terminals) skip .zprofile, so find Homebrew here if it is missing.
if [[ -z $HOMEBREW_PREFIX ]]; then
  for _p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x $_p/bin/brew ]]; then
      export HOMEBREW_PREFIX=$_p
      path=($_p/bin $_p/sbin $path)
      break
    fi
  done
  unset _p
fi

# Earlier entries win. Add your own in ~/.zsh.local:  path=($HOME/my/bin $path)
path=(
  $HOME/.local/bin
  $HOME/.bun/bin(N-/)
  $path
)
