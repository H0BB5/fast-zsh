# Login shells only. Homebrew's environment without forking `brew shellenv` (about 20ms).
# These are the exports `brew shellenv` prints, written out for Apple Silicon and Intel.
# Linuxbrew is rare enough that it keeps the real command.
typeset -U path fpath

if [[ -x /opt/homebrew/bin/brew ]]; then
  _hb=/opt/homebrew _hb_repo=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  _hb=/usr/local _hb_repo=/usr/local/Homebrew
fi

if [[ -n $_hb ]]; then
  export HOMEBREW_PREFIX=$_hb HOMEBREW_CELLAR=$_hb/Cellar HOMEBREW_REPOSITORY=$_hb_repo
  fpath=($_hb/share/zsh/site-functions $fpath)
  export FPATH
  path=($_hb/bin $_hb/sbin $path)
  [[ -z ${MANPATH-} ]] || { export MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"; export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"; }
  export INFOPATH="$_hb/share/info:${INFOPATH:-}"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
unset _hb _hb_repo

export PATH="$HOME/.local/bin:$PATH"
