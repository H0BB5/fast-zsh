#!/usr/bin/env bash
# Installs the fast-zsh config. Idempotent: safe to re-run to update.
# Works with the macOS system bash (3.2).
#
#   install.sh [--dry-run] [--no-brew] [--skip-node] [--hushlogin]
#
#   --dry-run     print every action, change nothing
#   --no-brew     do not install Homebrew packages (use when they are already present)
#   --skip-node   do not install a global node through mise
#   --hushlogin   create ~/.hushlogin to hide the "Last login" banner
set -u

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="$SKILL_DIR/config"
DEST="$HOME/.config/fast-zsh"
BACKUP="$HOME/.config-backups/fast-zsh-$(date +%Y%m%d-%H%M%S)"
FORMULAE="starship zoxide eza fd fzf mise hyperfine zsh-autosuggestions zsh-syntax-highlighting zsh-completions"

DRY=0; NO_BREW=0; SKIP_NODE=0; HUSH=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-brew) NO_BREW=1 ;;
    --skip-node) SKIP_NODE=1 ;;
    --hushlogin) HUSH=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
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
fi

# ── Config files ─────────────────────────────────────────────────
step "Config -> $DEST"
run mkdir -p "$DEST"
run rsync -a --delete "$CONFIG_SRC/" "$DEST/"
[ "$DRY" = 1 ] || say "  copied (personal changes belong in ~/.zsh.local, this directory is overwritten on update)"

backed_up=0
link() { # link <target> <link-path>
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
link "$DEST/.zshrc"        "$HOME/.zshrc"
link "$DEST/.zshenv"       "$HOME/.zshenv"
link "$DEST/.zprofile"     "$HOME/.zprofile"
link "$DEST/starship.toml" "$HOME/.config/starship.toml"

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
    say "  enabled .nvmrc / .node-version support"
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

# ── Warm caches and verify ───────────────────────────────────────
if [ "$DRY" = 0 ]; then
  step "Warming caches"
  zsh -l -i -c exit >/dev/null 2>&1; zsh -l -i -c exit >/dev/null 2>&1
  say "  done"
  step "Doctor"
  "$SKILL_DIR/scripts/doctor.sh" || true
  say ""
  say "Open a new terminal tab to start using it."
  [ "$backed_up" = 1 ] && say "Rollback: $SKILL_DIR/scripts/uninstall.sh"
fi
