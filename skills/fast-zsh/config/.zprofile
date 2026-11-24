# Login shells only. Homebrew once (exports HOMEBREW_*, PATH, FPATH, MANPATH).
# Covers Apple Silicon, Intel and Linuxbrew.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv)"
    break
  fi
done
unset _brew

export PATH="$HOME/.local/bin:$PATH"
