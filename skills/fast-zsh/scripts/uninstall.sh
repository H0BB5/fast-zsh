#!/usr/bin/env bash
# Removes the fast-zsh links and restores the most recent backup (or the one you name).
# Leaves ~/.zsh.local, ~/.config/fast-zsh and Homebrew packages in place.
#
#   uninstall.sh [backup-dir]
set -u

BACKUP="${1:-}"
if [ -z "$BACKUP" ]; then
  BACKUP="$(ls -1d "$HOME"/.config-backups/fast-zsh-* 2>/dev/null | tail -1)"
fi

for f in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.config/starship.toml"; do
  if [ -L "$f" ] && readlink "$f" | grep -q "/.config/fast-zsh/"; then
    rm "$f" && echo "removed link $f"
  fi
done

if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
  for f in .zshrc .zshenv .zprofile; do
    [ -e "$BACKUP/$f" ] && [ ! -e "$HOME/$f" ] && cp -P "$BACKUP/$f" "$HOME/$f" && echo "restored $HOME/$f"
  done
  [ -e "$BACKUP/starship.toml" ] && [ ! -e "$HOME/.config/starship.toml" ] && cp -P "$BACKUP/starship.toml" "$HOME/.config/starship.toml" && echo "restored ~/.config/starship.toml"
else
  echo "no backup found; shell will use zsh defaults"
fi
echo "Done. Open a new terminal tab."
