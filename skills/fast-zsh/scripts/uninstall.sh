#!/usr/bin/env bash
# Removes the fast-zsh lines from ~/.zshrc, ~/.zshenv and ~/.zprofile, removes the starship link, and
# restores the most recent backup (or the one you name). Lines that other tools appended to those
# files are kept, and the matching backup is left in place for you to merge by hand.
# Leaves ~/.zsh.local, ~/.config/fast-zsh and the Homebrew packages alone.
#
#   uninstall.sh [backup-dir]
set -u

BACKUP="${1:-}"
if [ -z "$BACKUP" ]; then
  BACKUP="$(ls -1d "$HOME"/.config-backups/fast-zsh-* 2>/dev/null | tail -1)"
fi
STUB_MARK="# fast-zsh: loads the managed config."
kept=""

for name in .zshrc .zshenv .zprofile; do
  p="$HOME/$name"
  if [ -L "$p" ] && readlink "$p" | grep -q "/.config/fast-zsh/"; then
    rm "$p" && echo "removed link $p"
  elif [ -f "$p" ] && grep -qF "$STUB_MARK" "$p"; then
    rest="$(grep -vF -e "$STUB_MARK" -e ".config/fast-zsh/$name" "$p" | grep -Ev '^[[:space:]]*$|^# Lines other tools had added')"
    if [ -n "$rest" ]; then
      grep -vF -e "$STUB_MARK" -e ".config/fast-zsh/$name" "$p" > "$p.fz-tmp" && mv "$p.fz-tmp" "$p"
      echo "removed the fast-zsh lines from $p and kept $(printf '%s\n' "$rest" | wc -l | tr -d ' ') line(s) added by other tools"
      kept="$kept $name"
    else
      rm "$p" && echo "removed $p"
    fi
  fi
done

sl="$HOME/.config/starship.toml"
if [ -L "$sl" ] && readlink "$sl" | grep -q "/.config/fast-zsh/"; then rm "$sl" && echo "removed link $sl"; fi

if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
  for f in .zshrc .zshenv .zprofile; do
    if [ -e "$BACKUP/$f" ] && [ ! -e "$HOME/$f" ]; then cp -P "$BACKUP/$f" "$HOME/$f" && echo "restored $HOME/$f"; fi
  done
  for f in $kept; do echo "note: ~/$f kept lines from other tools, so it was not overwritten. Your previous file is $BACKUP/$f, merge it by hand."; done
  [ -e "$BACKUP/starship.toml" ] && [ ! -e "$sl" ] && cp -P "$BACKUP/starship.toml" "$sl" && echo "restored $sl"
else
  echo "no backup found; zsh will use its defaults"
fi
echo "Done. Open a new terminal tab."
