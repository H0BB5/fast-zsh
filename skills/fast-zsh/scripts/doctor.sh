#!/usr/bin/env bash
# Read-only health check. Prints PASS / WARN / FAIL with a fix hint for each problem.
# Exit code 1 if anything FAILs. Works with the macOS system bash (3.2).
#
#   doctor.sh [--quick]     --quick skips the startup-time benchmark
set -u

QUICK=0; [ "${1:-}" = "--quick" ] && QUICK=1
DEST="$HOME/.config/fast-zsh"
PASS=0; WARN=0; FAIL=0
pass() { PASS=$((PASS+1)); printf '  PASS  %s\n' "$*"; }
info() { printf '  INFO  %s\n' "$*"; }
warn() { WARN=$((WARN+1)); printf '  WARN  %s\n' "$1"; [ -n "${2:-}" ] && printf '        fix: %s\n' "$2"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        fix: %s\n' "$2"; }

BREW=""; for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && BREW="$b" && break; done
[ -n "$BREW" ] && eval "$("$BREW" shellenv)"

echo "== Environment"
[ "$(uname -s)" = "Darwin" ] && pass "macOS $(sw_vers -productVersion) $(uname -m)" || warn "not macOS (untested)"
zv="$(zsh --version | awk '{print $2}')"
case "$zv" in 5.[89]*|5.[1-9][0-9]*|[6-9]*) pass "zsh $zv" ;; *) fail "zsh $zv is too old (need 5.8+)" "brew install zsh" ;; esac
[ -n "$BREW" ] && pass "Homebrew at $HOMEBREW_PREFIX" || fail "Homebrew not found" "install from https://brew.sh"

echo "== Tools"
for t in starship zoxide eza fd fzf mise; do
  command -v "$t" >/dev/null 2>&1 && pass "$t" || fail "$t missing" "brew install $t"
done
command -v hyperfine >/dev/null 2>&1 && pass "hyperfine" || warn "hyperfine missing (only needed for zshbench)" "brew install hyperfine"
command -v bat >/dev/null 2>&1 && pass "bat" || warn "bat missing (fzf file previews fall back to nothing)" "brew install bat"
for p in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/share/$p" ] && pass "plugin ${p%%/*}" || fail "plugin ${p%%/*} missing" "brew install ${p%%/*}"
done
[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions" ] && pass "plugin zsh-completions" || fail "plugin zsh-completions missing" "brew install zsh-completions"

echo "== Files"
chk() { # chk <link-path> <expected-target>
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then pass "$1 -> $2"
  elif [ -e "$1" ]; then fail "$1 exists but is not the fast-zsh link" "re-run install.sh (it backs the file up first)"
  else fail "$1 missing" "re-run install.sh"; fi
}
STUB_MARK="fast-zsh: loads the managed config."
chkstub() { # chkstub <dotfile name>
  local p="$HOME/$1"
  if [ -L "$p" ] && readlink "$p" | grep -q "/.config/fast-zsh/"; then
    warn "$p is a symlink into fast-zsh (older install): lines other tools append would land in a managed file that updates overwrite" "re-run install.sh to migrate it; nothing you added is lost"
  elif [ -f "$p" ] && grep -qF "$STUB_MARK" "$p" && grep -qF ".config/fast-zsh/$1" "$p"; then
    pass "$p loads ~/.config/fast-zsh/$1"
  elif [ -f "$p" ]; then
    fail "$p does not load the fast-zsh config" "re-run install.sh (it backs the file up first)"
  else
    fail "$p is missing" "re-run install.sh"
  fi
}
chkstub .zshrc
chkstub .zshenv
chkstub .zprofile
sl="$(readlink "$HOME/.config/starship.toml" 2>/dev/null)"
if [ "$sl" = "$DEST/starship-icons.toml" ]; then
  pass "$HOME/.config/starship.toml -> $sl"
  info "icon prompt is on: the terminal font must be 'JetBrainsMono Nerd Font Mono' (or another Nerd Font)"
else
  chk "$HOME/.config/starship.toml" "$DEST/starship.toml"
fi
if command -v delta >/dev/null 2>&1; then
  if [ "$(git config --global --get core.pager 2>/dev/null)" = "delta" ]; then pass "git pages diffs through delta"
  else info "delta is installed but git does not use it (optional: install.sh --git-delta)"; fi
fi
if [ -e "$HOME/.zsh.local" ]; then
  perm="$(ls -l "$HOME/.zsh.local" | cut -c1-10)"
  [ "$perm" = "-rw-------" ] && pass "~/.zsh.local mode 600" || warn "~/.zsh.local is $perm" "chmod 600 ~/.zsh.local"
fi

echo "== Shell startup"
errs="$(zsh -l -i -c exit 2>&1 >/dev/null | grep -v "can't change option: zle")"
if [ -z "$errs" ]; then pass "no errors or warnings on startup"
else fail "startup prints messages:" "see references/troubleshooting.md"; printf '%s\n' "$errs" | head -5 | sed 's/^/        /'; fi

bad="$(zsh -fc 'fpath=('"${HOMEBREW_PREFIX:-/opt/homebrew}"'/share/zsh-completions $fpath); autoload -Uz compaudit; compaudit' 2>/dev/null)"
if [ -z "$bad" ]; then pass "compaudit clean"; else for d in $bad; do fail "insecure completion dir: $d" "chmod go-w '$d' (sudo if you do not own it)"; done; fi

for c in starship mise zoxide fzf; do
  [ -s "$HOME/.cache/zsh/$c.zsh" ] && : || { warn "no init cache for $c yet" "open a new shell once; if it stays missing, run: $c --version"; }
done

paths="$(zsh -l -i -c 'print -l $path' 2>/dev/null)"
dups="$(printf '%s\n' "$paths" | sort | uniq -d | wc -l | tr -d ' ')"
[ "$dups" = 0 ] && pass "PATH has no duplicates" || warn "$dups duplicate PATH entries" "check ~/.zsh.local for path=(...) lines that do not end in \$path"

fns="$(zsh -l -i -c 'print -r -- $+functions[z] $+functions[fzf-history-widget] $+functions[_mise_hook]' 2>/dev/null | tail -1)"
[ "$fns" = "1 1 1" ] && pass "zoxide, fzf and mise hooks are loaded" || warn "tool hooks not loaded (z/fzf/mise: $fns)" "rm -rf ~/.cache/zsh && zsh -l -i -c exit"

echo "== Prompt"
# The prompt reads $STARSHIP_CONFIG, which users may set in ~/.zsh.local. Ask a login shell for it.
sc="$(zsh -l -i -c 'print -r -- ${STARSHIP_CONFIG:-}' 2>/dev/null | tail -1)"
if [ -n "$sc" ]; then export STARSHIP_CONFIG="$sc"; info "using your STARSHIP_CONFIG: $sc"; fi
if command -v starship >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
  pd="$(mktemp -d)"
  git -C "$pd" init -q -b main 2>/dev/null && git -C "$pd" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i 2>/dev/null
  branch_out="$(cd "$pd" && starship module git_branch 2>&1)"
  rm -rf "$pd"
  if printf '%s' "$branch_out" | grep -q "$(printf '\033')\[[0-9;]*m[^$(printf '\033')]*main"; then
    pass "git branch is colored in the prompt"
  else
    warn "git branch renders with no color" "an invalid color name in your starship config is ignored silently; valid names are black red green blue purple cyan white yellow (there is no 'magenta'), see references/prompt.md"
  fi
fi

echo "== Node"
if command -v mise >/dev/null 2>&1; then
  mise settings get idiomatic_version_file_enable_tools 2>/dev/null | grep -q node \
    && pass ".nvmrc / .node-version support on" \
    || warn ".nvmrc is ignored" "mise settings add idiomatic_version_file_enable_tools node"
  nv="$(mise exec -- node -v 2>/dev/null)"
  [ -n "$nv" ] && pass "node $nv via mise" || warn "no node from mise" "mise use -g node@lts"
fi
echo "== Startup files you or other tools edited"
hit=0
for f in .zshrc .zshenv .zprofile .zsh.local; do
  p="$HOME/$f"; [ -f "$p" ] && [ ! -L "$p" ] || continue
  n="$(grep -vF -e "$STUB_MARK" -e ".config/fast-zsh/$f" "$p" | grep -Evc '^[[:space:]]*(#|$)')"
  [ "$f" != ".zsh.local" ] && [ "${n:-0}" -gt 0 ] && info "~/$f has $n line(s) added by other tools (kept across updates)"
  for pat in 'oh-my-zsh' 'nvm\.sh|NVM_DIR' 'pyenv init' 'rbenv init' 'jenv init' 'conda initialize' 'compinit' 'sdkman-init' 'p10k|powerlevel10k'; do
    if grep -Eq "$pat" "$p"; then
      warn "~/$f contains '$pat' (slows every shell)" "remove it, or lazy-load it (see troubleshooting.md); mise replaces nvm"
      hit=1
    fi
  done
done
[ "$hit" = 0 ] && pass "no slow init lines found"

echo "== Fonts"
if [ -x "$(dirname "$0")/fonts.sh" ]; then
  fout="$("$(dirname "$0")/fonts.sh" check 2>&1 | sed '/^== /d; /^Fonts: /d; /^$/d')"
  printf '%s\n' "$fout"
  PASS=$((PASS + $(printf '%s\n' "$fout" | grep -c '^  PASS')))
  WARN=$((WARN + $(printf '%s\n' "$fout" | grep -c '^  WARN')))
  FAIL=$((FAIL + $(printf '%s\n' "$fout" | grep -c '^  FAIL')))
fi

if [ "$QUICK" = 0 ]; then
  echo "== Startup time"
  # One warmup run (macOS scans freshly installed binaries on first exec), then the median of five.
  ms="$(zsh -fc 'zmodload zsh/datetime zsh/mathfunc; zsh -l -i -c exit >/dev/null 2>&1; ts=(); for i in 1 2 3 4 5; do s=$EPOCHREALTIME; zsh -l -i -c exit >/dev/null 2>&1; ts+=( $(( int((EPOCHREALTIME - s) * 1000) )) ); done; ts=( ${(on)ts} ); print -r -- $ts[3]' 2>/dev/null)"
  if [ -z "$ms" ]; then warn "could not measure startup time"
  elif [ "$ms" -lt 250 ]; then pass "startup ${ms}ms median (target under 250ms)"
  elif [ "$ms" -lt 800 ]; then warn "startup ${ms}ms median" "run: zshprof   (per-function profile); managed-device security agents often add 100-300ms"
  else fail "startup ${ms}ms median" "run: zshprof   and fix the top entry"; fi
fi

echo
echo "Result: $PASS pass, $WARN warn, $FAIL fail"
[ "$FAIL" = 0 ]
