#!/usr/bin/env bash
# Removes the fast-zsh lines from ~/.zshrc, ~/.zshenv and ~/.zprofile, removes the starship link, and
# restores the most recent backup (or the one you name). If other tools added lines to those files
# while fast-zsh was installed, the previous file is restored and those lines are appended to it.
# Leaves ~/.zsh.local, ~/.config/fast-zsh and the Homebrew packages alone.
#
#   uninstall.sh [backup-dir]
set -u

BACKUP="${1:-}"
if [ -z "$BACKUP" ]; then
  BACKUP="$(ls -1d "$HOME"/.config-backups/fast-zsh-* 2>/dev/null | tail -1)"
fi
STUB_MARK="# fast-zsh: loads the managed config."
HEADERS='^# Lines (other tools had added|you or a tool added)'
handled=""

for name in .zshrc .zshenv .zprofile; do
  p="$HOME/$name"
  if [ -L "$p" ] && readlink "$p" | grep -q "/.config/fast-zsh/"; then
    rm "$p" && echo "removed link $p"
  elif [ -f "$p" ] && grep -qF "$STUB_MARK" "$p"; then
    stripped="$(grep -vF -e "$STUB_MARK" -e ".config/fast-zsh/$name" "$p" | grep -Ev "$HEADERS")"
    rest="$(printf '%s\n' "$stripped" | grep -Ev '^[[:space:]]*$')"
    if [ -z "$rest" ]; then
      rm "$p" && echo "removed $p"
    else
      n="$(printf '%s\n' "$rest" | wc -l | tr -d ' ')"
      if [ -n "$BACKUP" ] && [ -e "$BACKUP/$name" ]; then
        { cat "$BACKUP/$name"; printf '\n# Lines added by other tools while fast-zsh was installed (check for duplicates):\n'; printf '%s\n' "$rest"; } > "$p.fz-tmp" \
          && mv "$p.fz-tmp" "$p"
        echo "restored $p from the backup and appended the $n line(s) other tools added since"
      else
        printf '%s\n' "$stripped" > "$p.fz-tmp" && mv "$p.fz-tmp" "$p"
        echo "removed the fast-zsh lines from $p and kept $n line(s) added by other tools (no backup to restore)"
      fi
      handled="$handled $name"
    fi
  fi
done

sl="$HOME/.config/starship.toml"
if [ -L "$sl" ] && readlink "$sl" | grep -q "/.config/fast-zsh/"; then rm "$sl" && echo "removed link $sl"; fi

if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
  for f in .zshrc .zshenv .zprofile; do
    case " $handled " in *" $f "*) continue ;; esac
    if [ -e "$BACKUP/$f" ] && [ ! -e "$HOME/$f" ]; then cp -P "$BACKUP/$f" "$HOME/$f" && echo "restored $HOME/$f"; fi
  done
  [ -e "$BACKUP/starship.toml" ] && [ ! -e "$sl" ] && cp -P "$BACKUP/starship.toml" "$sl" && echo "restored $sl"
else
  echo "no backup found; zsh will use its defaults"
fi
echo "Done. Open a new terminal tab."
