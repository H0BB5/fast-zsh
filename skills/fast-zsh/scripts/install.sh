#!/usr/bin/env bash
# Installs the fast-zsh config. Idempotent: safe to re-run to update.
# Works with the macOS system bash (3.2).
#
#   install.sh [--dry-run] [--no-brew] [--skip-node] [--hushlogin] [--icons] [--git-delta]
#
#   --dry-run     print every action, change nothing
#   --no-brew     do not install Homebrew packages (use when they are already present)
#   --skip-node   do not install a global node through mise
#   --hushlogin   create ~/.hushlogin to hide the "Last login" banner
#   --icons       use the prompt variant with a branch icon, and install a Nerd Font
#                 (the terminal profile must then be set to that font)
#   --git-delta   install git-delta and make it git's pager (only if core.pager is unset)
set -u

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="$SKILL_DIR/config"
DEST="$HOME/.config/fast-zsh"
BACKUP="$HOME/.config-backups/fast-zsh-$(date +%Y%m%d-%H%M%S)"
FORMULAE="starship zoxide eza fd fzf bat mise hyperfine zsh-autosuggestions zsh-syntax-highlighting zsh-completions"
FONT_CASK="font-jetbrains-mono-nerd-font"

DRY=0; NO_BREW=0; SKIP_NODE=0; HUSH=0; ICONS=0; GIT_DELTA=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-brew) NO_BREW=1 ;;
    --skip-node) SKIP_NODE=1 ;;
    --hushlogin) HUSH=1 ;;
    --icons) ICONS=1 ;;
    --git-delta) GIT_DELTA=1 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# ── Preflight ────────────────────────────────────────────────────
step "Preflight"
if [ "$(uname -s)" != "Darwin" ]; then
  say "This installer targets macOS. Linux is untested; see references/troubleshooting.md." >&2
  exit 1
fi
command -v zsh >/dev/null || { say "zsh not found" >&2; exit 1; }
say "  zsh $(zsh --version | awk '{print $2}'), macOS $(sw_vers -productVersion), $(uname -m)"

BREW=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && BREW="$b" && break; done
if [ -z "$BREW" ]; then
  say "Homebrew is not installed. Install it first, then re-run:" >&2
  say '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
  exit 1
fi
eval "$("$BREW" shellenv)"
say "  Homebrew prefix: $HOMEBREW_PREFIX"

# ── Packages ─────────────────────────────────────────────────────
step "Packages"
if [ "$NO_BREW" = 1 ]; then
  say "  skipped (--no-brew)"
else
  installed="$(brew list --formula -1 2>/dev/null)"
  missing=""
  for f in $FORMULAE; do
    printf '%s\n' "$installed" | grep -qx "$f" || missing="$missing $f"
  done
  if [ -z "$missing" ]; then say "  all present"; else say "  installing:$missing"; run brew install $missing; fi
  if [ "$GIT_DELTA" = 1 ] && ! printf '%s\n' "$installed" | grep -qx git-delta; then
    say "  installing: git-delta"; run brew install git-delta
  fi
  if [ "$ICONS" = 1 ] && ! brew list --cask -1 2>/dev/null | grep -qx "$FONT_CASK"; then
    say "  installing font: $FONT_CASK"; run brew install --cask "$FONT_CASK"
  fi
fi

# ── Config files ─────────────────────────────────────────────────
step "Config -> $DEST"

# Nothing a user typed into a managed file may disappear silently. $DEST/.pristine holds the exact
# files from the last install, so a diff against it shows every hand edit, added module and deletion.
# Older versions linked ~/.zshrc straight into $DEST, so installers such as bun, gcloud and rustup
# also wrote into the three dotfiles. Lines added to those are carried into the real files below.
RESCUE="$(mktemp -d)"
for f in .zshrc .zshenv .zprofile; do
  [ -f "$DEST/$f" ] || continue
  base=""
  if [ -f "$DEST/.pristine/$f" ]; then base="$DEST/.pristine/$f"
  elif [ -f "$SKILL_DIR/scripts/legacy/$f" ]; then base="$SKILL_DIR/scripts/legacy/$f"   # v0.1.0 and v0.2.0 shipped these exact files
  fi
  [ -n "$base" ] && diff "$base" "$DEST/$f" | sed -n 's/^> //p' > "$RESCUE/$f"
done

managed_changed=""
if [ -f "$DEST/.pristine/.full" ]; then
  managed_changed="$(diff -rq "$DEST/.pristine" "$DEST" -x .pristine -x .full 2>/dev/null | sed "s|$DEST/.pristine|<last install>|g; s|$DEST|<managed>|g")"
fi
if [ -d "$DEST" ] && { [ -n "$managed_changed" ] || [ ! -f "$DEST/.pristine/.full" ]; }; then
  # Keep the previous managed copy. For an install made before full pristine copies existed this is
  # the only record of what was there.
  run mkdir -p "$BACKUP/managed-before-update"
  run rsync -a --exclude .pristine "$DEST/" "$BACKUP/managed-before-update/"
  if [ -n "$managed_changed" ]; then
    [ "$DRY" = 1 ] && verb="would be saved" || verb="are saved"
    say "  Files under $DEST were edited. The update overwrites them; your versions $verb in:"
    say "    $BACKUP/managed-before-update"
    printf '%s\n' "$managed_changed" | head -8 | sed 's/^/    /'
    say "  Move what you want to keep into ~/.zsh.local. Lines added to ~/.zshrc, ~/.zshenv or ~/.zprofile are carried over automatically."
  fi
fi

run mkdir -p "$DEST"
run rsync -a --delete --exclude .pristine "$CONFIG_SRC/" "$DEST/"
run mkdir -p "$DEST/.pristine"
run rsync -a --delete "$CONFIG_SRC/" "$DEST/.pristine/"
run touch "$DEST/.pristine/.full"
[ "$DRY" = 1 ] || say "  copied (personal changes belong in ~/.zsh.local; this directory is overwritten on update)"

# ~/.zshrc, ~/.zshenv and ~/.zprofile stay REAL files that load the managed copy. Tools that append
# to them (bun, gcloud, rustup, Homebrew's installer) then write into a file updates never touch.
STUB_MARK="# fast-zsh: loads the managed config."
KEPT_HEADER="# Lines you or a tool added to the managed file, carried over by the update:"
backed_up=0

carry() { # carry <dotfile-name> <real-path>: move lines typed into a managed dotfile into the real file
  local name="$1" path="$2" n
  [ -s "$RESCUE/$name" ] || return 0
  n="$(wc -l < "$RESCUE/$name" | tr -d ' ')"
  if [ "$DRY" = 1 ]; then say "  [dry-run] carry over $n line(s) added to the managed $name"; return 0; fi
  { printf '\n%s\n' "$KEPT_HEADER"; cat "$RESCUE/$name"; } >> "$path"
  say "  kept     $n line(s) added to the managed $name, now in $path"
}

stub() { # stub <dotfile-name>
  local name="$1" path="$HOME/$1"
  local l1="$STUB_MARK Lines other tools append below are kept across updates."
  local l2="[[ -r \"\$HOME/.config/fast-zsh/$name\" ]] && source \"\$HOME/.config/fast-zsh/$name\""

  if [ -f "$path" ] && [ ! -L "$path" ] && grep -qF "$STUB_MARK" "$path"; then
    if grep -qF "$l2" "$path"; then say "  ok       $path"; carry "$name" "$path"; return; fi
    # Marker present but the source line is gone (a tool rewrote the file): restore it at the top.
    if [ "$DRY" = 1 ]; then say "  [dry-run] restore source line in $path"; else
      { printf '%s\n%s\n' "$l1" "$l2"; grep -vF "$STUB_MARK" "$path"; } > "$path.fz-tmp" && mv "$path.fz-tmp" "$path"
      say "  repaired $path"
    fi
    carry "$name" "$path"
    return
  fi

  if [ -L "$path" ] && readlink "$path" | grep -q "/.config/fast-zsh/"; then
    run rm "$path"
    say "  migrate  $path was a link into fast-zsh"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    run mkdir -p "$BACKUP"
    run mv "$path" "$BACKUP/$name"
    backed_up=1
    say "  backup   $path -> $BACKUP/"
  fi

  if [ "$DRY" = 1 ]; then say "  [dry-run] write $path"; else
    printf '%s\n%s\n' "$l1" "$l2" > "$path"
    say "  write    $path"
  fi
  carry "$name" "$path"
}
stub .zshrc
stub .zshenv
stub .zprofile

link() { # link <target> <link-path>   (used for starship.toml, which tools do not append to)
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then say "  ok       $path"; return; fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    run mkdir -p "$BACKUP"
    run mv "$path" "$BACKUP/$(basename "$path")"
    backed_up=1
    say "  backup   $path -> $BACKUP/"
  fi
  run mkdir -p "$(dirname "$path")"
  run ln -s "$target" "$path"
  say "  link     $path -> $target"
}
if [ "$ICONS" = 1 ]; then STARSHIP_CFG="starship-icons.toml"; else STARSHIP_CFG="starship.toml"; fi
link "$DEST/$STARSHIP_CFG" "$HOME/.config/starship.toml"

# ── Terminal fonts (icon prompt only) ────────────────────────────
if [ "$ICONS" = 1 ]; then
  step "Terminal fonts"
  if [ "$DRY" = 1 ]; then "$SKILL_DIR/scripts/fonts.sh" apply --dry-run; else "$SKILL_DIR/scripts/fonts.sh" apply; fi
fi

# ── Leftovers from the old config ────────────────────────────────
if [ "$backed_up" = 1 ] && [ "$DRY" = 0 ]; then
  step "Found in your previous config ($BACKUP)"
  found=0
  for spec in \
    'oh-my-zsh:oh-my-zsh|ZSH_THEME' 'nvm:nvm\.sh|NVM_DIR' 'pyenv:pyenv init' 'rbenv:rbenv init' \
    'jenv:jenv init' 'conda:conda initialize' 'powerlevel10k:p10k|powerlevel10k' \
    'asdf:asdf\.sh' 'fnm:fnm env' 'direnv:direnv hook' 'sdkman:sdkman-init' \
    'zinit/antidote/zap:zinit|antidote|zap-zsh' 'aliases:^alias ' 'exports:^export ' \
    'possible secrets:API_KEY|TOKEN|SECRET|PASSWORD'; do
    name="${spec%%:*}"; pat="${spec#*:}"
    hits="$(cat "$BACKUP"/.zshrc "$BACKUP"/.zprofile "$BACKUP"/.zshenv 2>/dev/null | grep -Ec "$pat")"
    if [ "${hits:-0}" -gt 0 ]; then say "  $name ($hits lines)"; found=1; fi
  done
  [ "$found" = 0 ] && say "  nothing notable"
  say "  Port what you still need into ~/.zsh.local. Nothing was deleted."
fi
rm -rf "$RESCUE"

# ── ~/.zsh.local ─────────────────────────────────────────────────
step "~/.zsh.local"
if [ -e "$HOME/.zsh.local" ]; then
  say "  exists, left alone"
else
  if [ "$DRY" = 1 ]; then say "  [dry-run] create ~/.zsh.local (mode 600)"; else
    ( umask 077; cat > "$HOME/.zsh.local" <<'EOF'
# Machine-local and untracked. Sourced last, so anything here wins.
# Put personal aliases, PATH additions and secrets here.
#
#   path=($HOME/my/bin $path)
#   alias k=kubectl
#   export MY_API_KEY=...
#   export _ZO_EXCLUDE_DIRS="$_ZO_EXCLUDE_DIRS:*-wt-*"   # also hide <repo>-wt-<name> worktrees from zoxide
EOF
    )
    say "  created"
  fi
fi

# ── mise (node) ──────────────────────────────────────────────────
step "mise"
if command -v mise >/dev/null 2>&1 || [ "$DRY" = 1 ]; then
  if mise settings get idiomatic_version_file_enable_tools 2>/dev/null | grep -q node; then
    say "  .nvmrc / .node-version support already enabled"
  else
    run mise settings add idiomatic_version_file_enable_tools node
    [ "$DRY" = 1 ] || say "  enabled .nvmrc / .node-version support"
  fi
  if [ "$SKIP_NODE" = 1 ]; then
    say "  global node skipped (--skip-node)"
  elif grep -qs '^node' "$HOME/.config/mise/config.toml"; then
    say "  global node already configured"
  else
    run mise use -g node@lts
  fi
else
  say "  mise not found (run without --no-brew)"
fi

# ── compinit security check ──────────────────────────────────────
step "Completion directory permissions"
if [ "$DRY" = 1 ]; then say "  [dry-run] compaudit"; else
  bad="$(zsh -fc 'fpath=('"$HOMEBREW_PREFIX"'/share/zsh-completions $fpath); autoload -Uz compaudit; compaudit' 2>/dev/null)"
  if [ -z "$bad" ]; then say "  clean"; else
    for d in $bad; do
      if [ -O "$d" ]; then chmod go-w "$d" && say "  fixed    $d (removed group/other write)"
      else say "  NEEDS SUDO: sudo chmod go-w '$d'"; fi
    done
  fi
fi

# ── Optional ─────────────────────────────────────────────────────
if [ "$HUSH" = 1 ]; then run touch "$HOME/.hushlogin"; say "  created ~/.hushlogin"; fi

if [ "$GIT_DELTA" = 1 ]; then
  step "git-delta"
  if [ -n "$(git config --global --get core.pager 2>/dev/null)" ]; then
    say "  core.pager is already set to '$(git config --global --get core.pager)', left alone"
  else
    run git config --global core.pager delta
    run git config --global interactive.diffFilter 'delta --color-only'
    run git config --global delta.navigate true
    run git config --global delta.line-numbers true
    say "  git now pages diffs through delta (alias gdd = side-by-side)"
  fi
fi

# ── Warm caches and verify ───────────────────────────────────────
if [ "$DRY" = 0 ]; then
  step "Warming caches"
  zsh -l -i -c exit >/dev/null 2>&1; zsh -l -i -c exit >/dev/null 2>&1
  say "  done"
  step "Doctor"
  "$SKILL_DIR/scripts/doctor.sh"; doctor_rc=$?
  say ""
  say "Open a new terminal tab to start using it."
  if [ "$backed_up" = 1 ]; then say "Rollback: $SKILL_DIR/scripts/uninstall.sh"; fi
  exit "$doctor_rc"
fi
exit 0
