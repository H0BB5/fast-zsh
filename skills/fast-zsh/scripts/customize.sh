#!/usr/bin/env bash
# Applies look-and-feel choices. The skill's question flow calls this, and you can run it by hand.
# macOS bash 3.2 compatible. Everything it writes sits in a managed block or a file of its own, so
# re-running replaces the previous choice and `reset` removes it.
#
#   customize.sh starship  [--layout one|repo2|two] [--marker TEXT] [--git symbols|counts|icons|dot]
#                          [--icons] [--dir name|repo|last3|full] [--extras LIST] [--out FILE] [--dry-run]
#       LIST is comma separated from: duration status jobs claude worktree langs clock
#       Writes ~/.config/starship-mine.toml and points STARSHIP_CONFIG at it from ~/.zsh.local.
#   customize.sh theme     <theme>[/<variant>] [--check] [--no-ghostty] [--no-iterm] [--no-terminal] [--dry-run]
#       Installs a terminal color theme from https://terminalcolors.com/themes/ into Ghostty and cmux
#       (a managed block in ~/.config/ghostty/config), and imports it into iTerm and Terminal.app.
#   customize.sh highlight theme|vivid|subtle|default
#       Colors of what you type (zsh-syntax-highlighting), as a managed block in ~/.zsh.local.
#   customize.sh ligatures on|off
#       Ghostty and cmux font: JetBrainsMono Nerd Font Mono (ligatures) or the NL variant (none).
#   customize.sh reset
#       Removes every managed block written by this script and unsets STARSHIP_CONFIG.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_LOCAL="$HOME/.zsh.local"
GH_CONFIG="$HOME/.config/ghostty/config"
THEMES_URL="https://terminalcolors.com/themes/"
# The only top-level settings a downloaded theme may carry. A Terminal.app profile can also hold a command
# Terminal runs when it opens the profile (CommandString) or a different shell (Shell), so a file with any
# other setting is refused. Published themes hold colors, the font and a few profile fields.
TERMINAL_KEYS='^(.+Color|Font|FontAntialias|FontWidthSpacing|FontHeightSpacing|ProfileCurrentVersion|TerminalType|name|type)$'
ITERM_KEYS='^.+ Color( \((Light|Dark)\))?$'

say() { printf '%s\n' "$*"; }
die() { printf 'customize.sh: %s\n' "$*" >&2; exit 1; }
need() { [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"; }

# ── managed blocks ───────────────────────────────────────────────
block_remove() { # block_remove <file> <name>
  local file="$1" name="$2" tmp
  [ -f "$file" ] || return 0
  tmp="$(mktemp)"
  awk -v b="# >>> fast-zsh $name >>>" -v e="# <<< fast-zsh $name <<<" \
    '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$file" > "$tmp" && cat "$tmp" > "$file"
  rm -f "$tmp"
}
block_replace() { # block_replace <file> <name>   (new content on stdin)
  local file="$1" name="$2" content
  content="$(cat)"
  if [ ! -e "$file" ]; then mkdir -p "$(dirname "$file")"; ( umask 077; : > "$file" ); fi
  block_remove "$file" "$name"
  { printf '\n# >>> fast-zsh %s >>>\n' "$name"; printf '%s\n' "$content"; printf '# <<< fast-zsh %s <<<\n' "$name"; } >> "$file"
}

# ── starship ─────────────────────────────────────────────────────
cmd_starship() {
  local layout=one marker='$' git=symbols icons=0 dir=repo extras=duration out="$HOME/.config/starship-mine.toml" dry=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --layout) need "$@"; layout="$2"; shift 2 ;;
      --marker) need "$@"; marker="$2"; shift 2 ;;
      --git) need "$@"; git="$2"; shift 2 ;;
      --icons) icons=1; shift ;;
      --dir) need "$@"; dir="$2"; shift 2 ;;
      --extras)
        # An empty multi-select can produce a bare --extras. Treat it as "no extras": `shift 2` with one
        # argument left shifts nothing in bash, which looped forever.
        extras=""
        if [ $# -ge 2 ]; then case "$2" in --*) ;; *) extras="$2"; shift ;; esac; fi
        shift ;;
      --out) need "$@"; out="$2"; shift 2 ;;
      --dry-run) dry=1; shift ;;
      *) die "unknown starship option: $1" ;;
    esac
  done
  case "$layout" in one|repo2|two) ;; *) die "--layout must be one, repo2 or two" ;; esac
  case "$git" in symbols|counts|icons|dot) ;; *) die "--git must be symbols, counts, icons or dot" ;; esac
  case "$dir" in name|repo|last3|full) ;; *) die "--dir must be name, repo, last3 or full" ;; esac
  [ "$git" = icons ] && icons=1
  has() { case ",$extras," in *",$1,"*) return 0 ;; esac; return 1; }
  for x in $(printf '%s' "$extras" | tr ',' ' '); do
    case "$x" in duration|status|jobs|claude|worktree|langs|clock) ;; *) die "unknown extra: $x" ;; esac
  done

  # Escape the marker for TOML and starship: a backslash before each of  $ ( ) [ ] \  .
  local esc; esc="$(printf '%s' "$marker" | sed 's/[][$()\\]/\\\\&/g')"

  local fmt='$directory$git_branch$git_status'
  has worktree && fmt="$fmt"'${custom.worktree}'
  has jobs     && fmt="$fmt"'$jobs'
  has claude   && fmt="$fmt"'${env_var.CLAUDECODE}'
  has langs    && fmt="$fmt"'$nodejs$python$rust$golang'
  has duration && fmt="$fmt"'$cmd_duration'
  has status   && fmt="$fmt"'$status'
  case "$layout" in
    one)   fmt="$fmt"'$character' ;;
    two)   fmt="$fmt"'$line_break$character' ;;
    repo2) fmt="$fmt"'${custom.break}$character' ;;
  esac

  gen() {
    printf '# Generated by fast-zsh customize.sh. Re-run it to change choices; edit freely if you stop using it.\n'
    printf '# Colors are named ANSI colors, so they follow the terminal theme.\n'
    printf '"$schema" = '"'"'https://starship.rs/config-schema.json'"'"'\n\n'
    printf 'add_newline = false\ncommand_timeout = 500\nscan_timeout = 30\n\n'
    printf 'format = "%s"\n' "$fmt"
    has clock && printf 'right_format = "$time"\n'
    printf '\n[character]\nsuccess_symbol = "[%s](bold green) "\nerror_symbol = "[%s](bold red) "\n\n' "$esc" "$esc"

    printf '[directory]\nstyle = "bold cyan"\n'
    case "$dir" in
      name)  printf 'truncation_length = 1\ntruncate_to_repo = false\n' ;;
      repo)  printf 'truncation_length = 5\ntruncate_to_repo = true\n' ;;
      last3) printf 'truncation_length = 3\ntruncate_to_repo = false\ntruncation_symbol = "…/"\n' ;;
      full)  printf 'truncation_length = 0\ntruncate_to_repo = false\n' ;;
    esac
    printf '\n[git_branch]\n'
    if [ "$icons" = 1 ]; then printf 'symbol = "\\ue0a0 "\n'; else printf 'symbol = ""\n'; fi
    cat <<'EOF'
format = "[\\(](blue)[$symbol$branch]($style)[\\)](blue) "
style = "bold purple"
truncation_length = 36
truncation_symbol = "…"

EOF
    printf '[git_status]\nstyle = "bold yellow"\n'
    case "$git" in
      symbols) cat <<'EOF'
format = '([$all_status$ahead_behind]($style) )'
EOF
        ;;
      counts) cat <<'EOF'
format = '([$all_status$ahead_behind]($style))'
conflicted = "=${count} "
stashed = "\\$${count} "
deleted = "✘${count} "
renamed = "»${count} "
modified = "!${count} "
typechanged = "~${count} "
staged = "+${count} "
untracked = "?${count} "
ahead = "⇡${count} "
behind = "⇣${count} "
diverged = "⇕ ⇡${ahead_count} ⇣${behind_count} "
up_to_date = ""
EOF
        ;;
      icons) cat <<'EOF'
format = '([$all_status$ahead_behind]($style))'
conflicted = "\uf071${count} "
stashed = "\uf187${count} "
deleted = "\uf014${count} "
renamed = "\uf0ec${count} "
modified = "\uf040${count} "
typechanged = "\uf0ad${count} "
staged = "\uf067${count} "
untracked = "\uf128${count} "
ahead = "\uf062${count} "
behind = "\uf063${count} "
diverged = "\uf0dc \uf062${ahead_count} \uf063${behind_count} "
up_to_date = ""
EOF
        ;;
      dot) cat <<'EOF'
format = '([$all_status$ahead_behind]($style) )'
conflicted = "●"
stashed = ""
deleted = "●"
renamed = "●"
modified = "●"
typechanged = "●"
staged = "●"
untracked = "●"
ahead = ""
behind = ""
diverged = ""
up_to_date = ""
EOF
        ;;
    esac
    printf '\n'
    if has worktree; then
      # Two git calls per prompt, and only inside a repo. Absolute paths: the relative ones differ per directory.
      printf '[custom.worktree]\ncommand = '"'"'basename "$(git rev-parse --show-toplevel)"'"'"'\n'
      printf 'when = '"'"'[ "$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)" != "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" ]'"'"'\n'
      if [ "$icons" = 1 ]; then printf 'format = "[\\uf126 $output]($style) "\n'; else printf 'format = "[wt:$output]($style) "\n'; fi
      printf 'style = "bold bright-cyan"\n\n'
    fi
    if has jobs; then
      printf '[jobs]\nnumber_threshold = 1\nstyle = "bold blue"\n'
      if [ "$icons" = 1 ]; then printf 'symbol = "\\uf013 "\nformat = "[$symbol$number]($style) "\n\n'; else printf 'format = "[jobs:$number]($style) "\n\n'; fi
    fi
    if has claude; then
      printf '[env_var.CLAUDECODE]\nvariable = "CLAUDECODE"\nformat = "[✻ claude]($style) "\nstyle = "bold bright-purple"\n\n'
    fi
    if has langs; then
      cat <<'EOF'
[nodejs]
disabled = false
format = "[node ($version )]($style)"
style = "bold green"
[python]
disabled = false
format = "[py ($version )]($style)"
style = "bold green"
[rust]
disabled = false
format = "[rs ($version )]($style)"
style = "bold green"
[golang]
disabled = false
format = "[go ($version )]($style)"
style = "bold green"

EOF
    fi
    if has duration; then printf '[cmd_duration]\nmin_time = 2000\nformat = "[$duration]($style) "\n\n'; fi
    if has status; then printf '[status]\ndisabled = false\nformat = "[$symbol$status]($style) "\nsymbol = "✘ "\nstyle = "bold red"\n\n'; fi
    if has clock; then printf '[time]\ndisabled = false\nformat = "[$time]($style)"\ntime_format = "%%H:%%M"\nstyle = "dimmed white"\n\n'; fi
    if [ "$layout" = repo2 ]; then
      printf '# Starts the second line, but only inside a git repository.\n[custom.break]\ncommand = "true"\nwhen = "git rev-parse --git-dir"\nformat = "\\n"\n\n'
    fi
    printf '# These probe the filesystem on every prompt. Off unless chosen above.\n[package]\ndisabled = true\n[docker_context]\ndisabled = true\n[java]\ndisabled = true\n'
    has langs || printf '[nodejs]\ndisabled = true\n[python]\ndisabled = true\n[rust]\ndisabled = true\n[golang]\ndisabled = true\n'
  }

  if [ "$dry" = 1 ]; then gen; return 0; fi
  command -v starship >/dev/null 2>&1 || die "starship is not installed (brew install starship)"
  local tmp tdir problems; tmp="$(mktemp)"; gen > "$tmp"
  # Validate before replacing anything: render once in a temp git repo and require a clean run.
  tdir="$(mktemp -d)"
  git -C "$tdir" init -q -b main 2>/dev/null && git -C "$tdir" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i 2>/dev/null
  problems="$(cd "$tdir" && STARSHIP_CONFIG="$tmp" starship prompt 2>&1 >/dev/null)"
  rm -rf "$tdir"
  if [ -n "$problems" ]; then rm -f "$tmp"; die "the generated config is invalid:
$problems"; fi
  mkdir -p "$(dirname "$out")"; mv "$tmp" "$out"
  block_replace "$ZSH_LOCAL" starship <<EOF
export STARSHIP_CONFIG="$out"
EOF
  say "wrote $out and pointed STARSHIP_CONFIG at it from ~/.zsh.local"
  [ "$icons" = 1 ] && say "icons are on: the terminal font must be a Nerd Font Mono (fonts.sh check)"
  say "open a new tab to see it"
}

# ── terminal theme ───────────────────────────────────────────────
# plist_extra_keys <file> <ERE>: print the top-level settings that do not match <ERE>, and fail if there are any.
# `plutil -lint` only proves a file parses. The XML form indents top-level keys with exactly one tab, so they
# can be listed without a plist library; nested keys (inside an iTerm color) are indented further.
plist_extra_keys() {
  local tab keys extra
  tab="$(printf '\t')"
  keys="$(plutil -convert xml1 -o - "$1" 2>/dev/null | sed -n "s/^${tab}<key>\(.*\)<\/key>\$/\1/p")"
  if [ -z "$keys" ]; then echo "not a settings dictionary"; return 1; fi
  extra="$(printf '%s\n' "$keys" | grep -Ev "$2" | tr '\n' ' ' | sed 's/ $//')"
  [ -z "$extra" ] || { printf '%s\n' "$extra"; return 1; }
}

cmd_theme() {
  local arg1="${1-}" arg2="" check=0 gh=1 it=1 tm=1 dry=0
  [ -n "$arg1" ] || die "usage: customize.sh theme <theme>[/<variant>]   (browse $THEMES_URL)"
  shift
  case "${1-}" in -*|"") ;; *) arg2="$1"; shift ;; esac
  while [ $# -gt 0 ]; do
    case "$1" in
      --check) check=1 ;; --no-ghostty) gh=0 ;; --no-iterm) it=0 ;; --no-terminal) tm=0 ;; --dry-run) dry=1 ;;
      *) die "unknown theme option: $1" ;;
    esac; shift
  done
  local theme variant
  case "$arg1" in */*) theme="${arg1%%/*}"; variant="${arg1#*/}" ;; *) theme="$arg1"; variant="${arg2:-default}" ;; esac
  for part in "$theme" "$variant"; do
    printf '%s' "$part" | grep -Eq '^[a-z0-9][a-z0-9-]*$' || die "theme and variant are lowercase letters, digits and hyphens, as in the page URL ${THEMES_URL}<theme>/<variant>"
  done
  local slug="$theme-$variant" base="https://terminalcolors.com/downloads"
  local gh_url="$base/ghostty/$slug" it_url="$base/iterm2/$slug.itermcolors" tm_url="$base/terminal-app/$slug.terminal"
  local fetch=(curl -fsSL --proto '=https' --max-time 20)

  # The site answers HTTP 200 for any name (unknown ones get a web page), so a theme exists only if the
  # downloaded file holds a full palette: background, foreground and 16 ANSI colors (18+ valid lines).
  allow() { grep -E '^(background|foreground|selection-background|selection-foreground|cursor-color|cursor-text) = #[0-9a-fA-F]{6}$|^palette = ([0-9]|1[0-5])=#[0-9a-fA-F]{6}$'; }
  local not_found="no theme named $theme/$variant. Copy the exact name from ${THEMES_URL} (the part of the page URL after /themes/)."
  if [ "$check" = 1 ]; then
    local cdir; cdir="$(mktemp -d)"
    if "${fetch[@]}" -o "$cdir/g" "$gh_url" 2>/dev/null && [ "$(allow < "$cdir/g" | wc -l | tr -d ' ')" -ge 18 ]; then
      rm -rf "$cdir"; say "found: $theme/$variant"; return 0
    fi
    rm -rf "$cdir"; die "$not_found"
  fi
  if [ "$dry" = 1 ]; then
    say "would download $gh_url"; [ "$it" = 1 ] && say "would import $it_url into iTerm"; [ "$tm" = 1 ] && say "would import $tm_url into Terminal.app"; return 0
  fi

  # Downloads are untrusted data: each goes into its own new directory, only an allow-list of lines is used
  # for Ghostty, and a plist file is opened only when it parses and every setting in it is on an allow-list.
  local d; d="$(mktemp -d)"
  if [ "$gh" = 1 ] && { [ -d /Applications/Ghostty.app ] || [ -d /Applications/cmux.app ] || [ -f "$GH_CONFIG" ]; }; then
    "${fetch[@]}" -o "$d/ghostty" "$gh_url" || { rm -rf "$d"; die "could not download $theme/$variant. Check the name at ${THEMES_URL}"; }
    allow < "$d/ghostty" > "$d/clean"
    [ "$(wc -l < "$d/clean" | tr -d ' ')" -ge 18 ] || { rm -rf "$d"; die "$not_found Nothing was changed."; }
    mkdir -p "$(dirname "$GH_CONFIG")"
    block_replace "$GH_CONFIG" theme <<EOF
# Color theme: $theme/$variant from terminalcolors.com. cmux reads this file too, and uses these colors
# instead of its adaptive default palette.
$(cat "$d/clean")
EOF
    say "Ghostty and cmux: wrote $theme/$variant to $GH_CONFIG. Reload with Cmd-Shift-comma (cmux: cmux reload-config)."
  fi
  if [ "$it" = 1 ] && [ -d /Applications/iTerm.app ]; then
    if "${fetch[@]}" -o "$d/$slug.itermcolors" "$it_url" 2>/dev/null && plutil -lint "$d/$slug.itermcolors" >/dev/null 2>&1; then
      if extra="$(plist_extra_keys "$d/$slug.itermcolors" "$ITERM_KEYS")"; then
        open -a iTerm "$d/$slug.itermcolors" && say "iTerm: imported the color preset. Select it once: Settings > Profiles > Colors > Color Presets > $theme."
      else say "iTerm: the preset for $theme/$variant holds more than colors ($extra), so it was not imported"; fi
    else say "iTerm: no preset published for $theme/$variant, skipped"; fi
  fi
  if [ "$tm" = 1 ]; then
    if "${fetch[@]}" -o "$d/$slug.terminal" "$tm_url" 2>/dev/null && plutil -lint "$d/$slug.terminal" >/dev/null 2>&1; then
      if ! extra="$(plist_extra_keys "$d/$slug.terminal" "$TERMINAL_KEYS")"; then
        say "Terminal.app: the profile for $theme/$variant holds settings other than colors and font ($extra), so it was not imported"
      else
        open -a Terminal "$d/$slug.terminal" && say "Terminal.app: imported the profile '$slug'. Make it the default once: Settings > Profiles > $slug > Default."
        sleep 4
        if find -L "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -name 'JetBrainsMonoNerdFontMono-*' 2>/dev/null | grep -q .; then
          # The imported profile brings its own font. Give it the Nerd Font so icons render (cannot hang: 25s cap).
          osascript -e "tell application \"Terminal\" to set font name of settings set \"$slug\" to \"JetBrainsMonoNFM-Regular\"" \
                    -e "tell application \"Terminal\" to set font size of settings set \"$slug\" to 12" >/dev/null 2>&1 &
          local pid=$! i=0
          while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 25 ]; do sleep 1; i=$((i + 1)); done
          if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null; say "Terminal.app: could not set the font (needs an Automation approval). Set it by hand: Settings > Profiles > $slug > Text > Font."
          else say "Terminal.app: set the profile font to JetBrainsMono Nerd Font Mono."; fi
        fi
      fi
    else say "Terminal.app: no profile published for $theme/$variant, skipped"; fi
  fi
  rm -rf "$d"
}

# ── typed-command colors ─────────────────────────────────────────
cmd_highlight() {
  local style="${1-}"
  case "$style" in
    theme) block_replace "$ZSH_LOCAL" highlight <<'EOF'
# Typed-command colors: named ANSI colors that follow the terminal theme.
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=cyan,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=blue'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta'
EOF
      ;;
    vivid) block_replace "$ZSH_LOCAL" highlight <<'EOF'
# Typed-command colors: vivid (256-color numbers, fixed regardless of the terminal theme).
ZSH_HIGHLIGHT_STYLES[command]='fg=208,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=201'
ZSH_HIGHLIGHT_STYLES[function]='fg=208'
ZSH_HIGHLIGHT_STYLES[alias]='fg=51'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=51,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=75,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=196,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=135'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=220'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=220'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
EOF
      ;;
    subtle) block_replace "$ZSH_LOCAL" highlight <<'EOF'
# Typed-command colors: subtle (muted 256-color numbers, underline for valid paths).
ZSH_HIGHLIGHT_STYLES[command]='fg=108'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=108'
ZSH_HIGHLIGHT_STYLES[function]='fg=108'
ZSH_HIGHLIGHT_STYLES[alias]='fg=109'
ZSH_HIGHLIGHT_STYLES[path]='underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=131'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=179'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=179'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
EOF
      ;;
    default) block_remove "$ZSH_LOCAL" highlight; say "typed-command colors are back to the plugin defaults"; return 0 ;;
    *) die "usage: customize.sh highlight theme|vivid|subtle|default" ;;
  esac
  say "typed-command colors set to '$style' in ~/.zsh.local. Open a new tab to see them."
}

# ── ligatures ────────────────────────────────────────────────────
cmd_ligatures() {
  case "${1-}" in
    on)  "$HERE/fonts.sh" apply --force ;;
    off) "$HERE/fonts.sh" apply --no-ligatures --force ;;
    *) die "usage: customize.sh ligatures on|off" ;;
  esac
  say "iTerm and Terminal.app keep the font in the profile: pick JetBrainsMono Nerd Font Mono (ligatures) or JetBrainsMonoNL Nerd Font Mono (none)."
}

cmd_reset() {
  block_remove "$ZSH_LOCAL" starship; block_remove "$ZSH_LOCAL" highlight; block_remove "$GH_CONFIG" theme
  say "removed the managed blocks from ~/.zsh.local and the Ghostty config. ~/.config/starship-mine.toml is kept if you want it."
  say "the prompt is back on the installed config; imported iTerm presets and Terminal.app profiles stay until you delete them in their settings."
}

case "${1-}" in
  starship)  shift; cmd_starship "$@" ;;
  theme)     shift; cmd_theme "$@" ;;
  highlight) shift; cmd_highlight "$@" ;;
  ligatures) shift; cmd_ligatures "$@" ;;
  reset)     cmd_reset ;;
  -h|--help|"") sed -n '2,22p' "$0" ;;
  *) die "unknown command: $1 (starship, theme, highlight, ligatures, reset)" ;;
esac
