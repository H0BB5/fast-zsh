#!/usr/bin/env bash
# Terminal font and rendering helper for the fast-zsh icon prompt. macOS bash 3.2 compatible.
#
#   fonts.sh check                                  read-only report on installed Nerd Fonts and on the
#                                                   font settings of Ghostty, cmux, iTerm2 and Terminal.app
#   fonts.sh apply [--no-ligatures] [--force] [--dry-run]
#                                                   set font-family for Ghostty and cmux (one shared file),
#                                                   and print the exact steps for iTerm2 and Terminal.app
#
# Why the Mono variant: a terminal draws on a fixed grid. "Nerd Font Mono" squeezes every icon into one
# cell, "Nerd Font" lets icons spill over, and "Nerd Font Propo" has proportional widths that break the
# grid. Kerning does not apply on a grid, so the only spacing knobs (horizontal and vertical spacing,
# Ghostty's adjust-cell-*) should stay at their defaults.
set -u

FAMILY="JetBrainsMono Nerd Font Mono"
FAMILY_NL="JetBrainsMonoNL Nerd Font Mono"          # same font without programming ligatures
GH_XDG="$HOME/.config/ghostty/config"                # read by Ghostty and by cmux
GH_APP_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"

PASS=0; WARN=0; FAIL=0
pass() { PASS=$((PASS+1)); printf '  PASS  %s\n' "$*"; }
info() { printf '  INFO  %s\n' "$*"; }
warn() { WARN=$((WARN+1)); printf '  WARN  %s\n' "$1"; [ -n "${2:-}" ] && printf '        fix: %s\n' "$2"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        fix: %s\n' "$2"; }

count_fonts() { find -L "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -name "$1" 2>/dev/null | wc -l | tr -d ' '; }
# True when the active starship config draws the branch icon (U+E0A0), the only thing that needs a Nerd Font.
icons_on() { grep -qs -e 'ue0a0' -e "$(printf '\356\202\240')" "${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"; }
have_py() { xcode-select -p >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; }

# Last font-family value in a Ghostty-style config file, without quotes.
gh_value() {
  [ -f "$1" ] || return 0
  sed -n 's/^[[:space:]]*font-family[[:space:]]*=[[:space:]]*//p' "$1" | tail -1 | sed 's/^"//; s/"[[:space:]]*$//; s/[[:space:]]*$//'
}

# judge <label> <font name or PostScript name>
judge() {
  case "$2" in
    *Propo*|*NFP*)
      # Proportional widths break a terminal's grid whatever the prompt draws, so it always matters;
      # it only fails the doctor when the icon prompt depends on the font.
      if icons_on; then fail "$1 uses a Propo font ('$2')" "pick a Mono variant: $FAMILY"
      else warn "$1 uses a Propo font ('$2'): glyph widths vary and break the grid" "pick a Mono variant: $FAMILY"; fi ;;
    *"Nerd Font Mono"*|*NFM*) pass "$1: $2" ;;
    *NerdFont*|*"Nerd Font"*|*NF-*)
      if icons_on; then warn "$1 uses a non-Mono Nerd Font ('$2'): icons can spill over their cell" "pick $FAMILY"
      else info "$1: '$2' is a non-Mono Nerd Font (icons can spill over a cell; only matters with the icon prompt)"; fi ;;
    *)
      if icons_on; then warn "$1 uses '$2', which is not a Nerd Font, so the branch icon shows as a box" "pick $FAMILY"
      else info "$1: '$2' is not a Nerd Font (only matters for the icon prompt)"; fi ;;
  esac
}

# off_by_more_than_one_percent <number>
spacing_off() { awk -v v="$1" 'BEGIN { exit !(v+0 < 0.99 || v+0 > 1.01) }'; }

check() {
  echo "== Installed fonts"
  nfm="$(count_fonts 'JetBrainsMonoNerdFontMono-*')"; nl="$(count_fonts 'JetBrainsMonoNLNerdFontMono-*')"
  nfp="$(count_fonts '*NerdFontPropo-*')"
  if [ "$nfm" -gt 0 ]; then pass "$FAMILY ($nfm files)"
  elif icons_on; then fail "$FAMILY is not installed but the icon prompt is on" "brew install --cask font-jetbrains-mono-nerd-font"
  else info "$FAMILY is not installed (only needed for the icon prompt: install.sh --icons)"; fi
  [ "$nl" -gt 0 ] && info "$FAMILY_NL is available (no ligatures)"
  [ "$nfp" -gt 0 ] && info "Propo variants are installed. Never select them in a terminal, their glyph widths vary."

  echo "== Ghostty and cmux"
  if [ -d /Applications/Ghostty.app ] || [ -d /Applications/cmux.app ]; then
    xdg="$(gh_value "$GH_XDG")"; app="$(gh_value "$GH_APP_DIR/config.ghostty")"; [ -z "$app" ] && app="$(gh_value "$GH_APP_DIR/config")"
    if [ -d /Applications/cmux.app ]; then
      if [ ! -f "$GH_XDG" ]; then
        if icons_on; then warn "cmux reads only ~/.config/ghostty/config and that file does not exist" "fonts.sh apply"
        else info "cmux reads only ~/.config/ghostty/config and that file does not exist"; fi
      elif [ -n "$xdg" ]; then judge "cmux (~/.config/ghostty/config)" "$xdg"
      else info "cmux: ~/.config/ghostty/config sets no font-family"; fi
    fi
    if [ -d /Applications/Ghostty.app ]; then
      eff="${app:-$xdg}"
      if [ -n "$xdg" ] && [ -n "$app" ] && [ "$xdg" != "$app" ]; then
        warn "Ghostty has two font-family values ('$xdg' and '$app'); the Application Support file wins" "keep one, in ~/.config/ghostty/config"
      fi
      if [ -n "$eff" ]; then judge "Ghostty" "$eff"
      else info "Ghostty: no font-family set. Its built-in fallback still draws Nerd Font icons."; fi
    fi
    for k in font-thicken alpha-blending adjust-cell-width adjust-cell-height font-feature; do
      for f in "$GH_XDG" "$GH_APP_DIR/config.ghostty" "$GH_APP_DIR/config"; do
        [ -f "$f" ] && grep -E "^[[:space:]]*${k}[[:space:]]*=" "$f" | tail -1 | sed "s|^|  INFO  rendering ($(basename "$f")): |"
      done
    done
  else
    info "Ghostty and cmux not installed"
  fi

  echo "== iTerm2"
  if [ -d /Applications/iTerm.app ]; then
    if have_py; then
      prof="$(defaults export com.googlecode.iterm2 - 2>/dev/null | python3 -I -c '
import sys, plistlib
d = plistlib.loads(sys.stdin.buffer.read())
g = d.get("Default Bookmark Guid")
for b in d.get("New Bookmarks", []):
    if b.get("Guid") == g:
        for k in ("Normal Font","Use Non-ASCII Font","ASCII Anti Aliased","Non-ASCII Anti Aliased","Horizontal Spacing","Vertical Spacing","ASCII Ligatures"):
            print("%s=%s" % (k, b.get(k, "")))
' 2>/dev/null)"
      if [ -z "$prof" ]; then info "could not read the default profile"; else
        val() { printf '%s\n' "$prof" | sed -n "s/^$1=//p"; }
        judge "iTerm2 default profile" "$(val 'Normal Font')"
        [ "$(val 'Use Non-ASCII Font')" = "True" ] && warn "iTerm2 uses a second font for non-ASCII text, which can mismatch icon widths" "Settings > Profiles > Text, untick 'Use a different font for non-ASCII text'"
        [ "$(val 'ASCII Anti Aliased')" = "False" ] && warn "iTerm2 anti-aliasing is off for ASCII text" "Settings > Profiles > Text, tick 'Anti-aliased'"
        for k in "Horizontal Spacing" "Vertical Spacing"; do
          v="$(val "$k")"; [ -n "$v" ] && spacing_off "$v" && warn "iTerm2 $k is $v (default 1.0): uneven glyph spacing" "Settings > Profiles > Text, set spacing back to 100%"
        done
        [ "$(val 'ASCII Ligatures')" = "True" ] && info "iTerm2 ligatures are on" || info "iTerm2 ligatures are off"
      fi
    else info "skipped (needs python3 from the Xcode Command Line Tools)"; fi
  else info "iTerm2 not installed"; fi

  echo "== Terminal.app"
  if have_py; then
    tprof="$(defaults export com.apple.Terminal - 2>/dev/null | python3 -I -c '
import sys, plistlib
d = plistlib.loads(sys.stdin.buffer.read())
name = d.get("Default Window Settings", "Basic")
p = d.get("Window Settings", {}).get(name, {})
font = ""
if p.get("Font"):
    objs = plistlib.loads(p["Font"]).get("$objects", [])
    strs = [o for o in objs if isinstance(o, str) and o != "$null"]
    font = strs[0] if strs else ""
print("profile=%s" % name)
print("font=%s" % (font or "SF Mono (system default)"))
print("antialias=%s" % p.get("FontAntialiasing", True))
print("width=%s" % p.get("FontWidthSpacing", 1.0))
print("height=%s" % p.get("FontHeightSpacing", 1.0))
' 2>/dev/null)"
    if [ -z "$tprof" ]; then info "could not read Terminal.app settings"; else
      tval() { printf '%s\n' "$tprof" | sed -n "s/^$1=//p"; }
      judge "Terminal.app profile '$(tval profile)'" "$(tval font)"
      [ "$(tval antialias)" = "False" ] && warn "Terminal.app 'Antialias text' is off" "Settings > Profiles > Text, tick 'Antialias text'"
      for k in width height; do
        v="$(tval $k)"; [ -n "$v" ] && spacing_off "$v" && warn "Terminal.app $k spacing is $v (default 1)" "Settings > Profiles > Text, set Character/Line spacing to 1"
      done
      info "Terminal.app cannot render programming ligatures"
    fi
  else info "skipped (needs python3 from the Xcode Command Line Tools)"; fi

  echo; echo "Fonts: $PASS pass, $WARN warn, $FAIL fail"
  [ "$FAIL" = 0 ]
}

apply() {
  fam="$FAMILY"; force=0; dry=0
  for a in "$@"; do
    case "$a" in
      --no-ligatures) fam="$FAMILY_NL" ;;
      --force) force=1 ;;
      --dry-run) dry=1 ;;
      *) echo "unknown flag: $a" >&2; exit 2 ;;
    esac
  done
  say() { printf '%s\n' "$*"; }

  if [ "$(count_fonts 'JetBrainsMono*NerdFontMono-*')" = 0 ]; then
    say "  The Nerd Font is not installed. Run: brew install --cask font-jetbrains-mono-nerd-font"
    [ "$dry" = 1 ] || exit 1
  fi

  say "  Ghostty and cmux share $GH_XDG"
  cur="$(gh_value "$GH_XDG")"
  if [ -z "$cur" ]; then
    if [ "$dry" = 1 ]; then say "  [dry-run] add: font-family = \"$fam\""; else
      mkdir -p "$(dirname "$GH_XDG")"
      printf 'font-family = "%s"\n' "$fam" >> "$GH_XDG"
      say "  wrote    font-family = \"$fam\""
    fi
  else
    case "$cur" in
      *"Nerd Font Mono"*) say "  ok       font-family is already '$cur'" ;;
      *)
        if [ "$force" = 1 ] && [ "$dry" = 0 ]; then
          sed "s|^[[:space:]]*font-family[[:space:]]*=.*|font-family = \"$fam\"|" "$GH_XDG" > "$GH_XDG.fz-tmp" && mv "$GH_XDG.fz-tmp" "$GH_XDG"
          say "  replaced font-family '$cur' with '$fam'"
        else say "  left alone: font-family is '$cur' (use --force to replace it)"; fi ;;
    esac
  fi
  app="$(gh_value "$GH_APP_DIR/config.ghostty")"; [ -z "$app" ] && app="$(gh_value "$GH_APP_DIR/config")"
  [ -n "$app" ] && say "  note     Ghostty also has font-family '$app' in Application Support, and that file wins over the one above"
  say "  reload   Cmd-Shift-comma in Ghostty, or Cmd-Shift-comma / 'cmux reload-config' in cmux."
  say "           Panes that are already open can keep the old font until they are reopened."

  say ""
  say "  iTerm2 (not scriptable without replacing your profile, so set it once by hand):"
  say "    Settings > Profiles > Text > Font: \"$fam\", Regular weight"
  say "    tick 'Anti-aliased', untick 'Use a different font for non-ASCII text', spacing 100% / 100%"
  say "  Terminal.app:"
  say "    Settings > Profiles > <your profile> > Text > Font > Change: Family \"$fam\", Typeface Regular"
  say "    keep 'Antialias text' ticked and Character spacing / Line spacing at 1"
  say ""
  say "  Optional Ghostty and cmux lines for ~/.config/ghostty/config:"
  say "    font-thicken = true         heavier strokes if text looks thin on your display"
  say "    font-feature = -calt        turn programming ligatures off (or use --no-ligatures)"
  say "  Never choose a Propo font in a terminal, and leave spacing at its defaults: the grid handles alignment."
}

case "${1:-check}" in
  check) check ;;
  apply) shift; apply "$@" ;;
  -h|--help) sed -n '2,13p' "$0" ;;
  *) echo "usage: fonts.sh check | apply [--no-ligatures] [--force] [--dry-run]" >&2; exit 2 ;;
esac
