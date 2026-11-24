# Troubleshooting

Run `scripts/doctor.sh` first.
Most entries below are what its `fix:` lines point at.

## Startup prints errors or "compinit: initialization aborted"

Completion directories must not be group or world writable.
Homebrew's `share` directory is often mode 775.

```
zsh -fc 'fpath=($(brew --prefix)/share/zsh-completions $fpath); autoload -Uz compaudit; compaudit'
chmod go-w <each directory it prints>
```

If you do not own the directory, ask the user before using `sudo chmod go-w`.

## Startup is slower than 250ms

Run `zshprof`.
The top entry is the cause.

- `nvm`, `pyenv`, `rbenv`, `jenv`, `conda`, `sdkman` init lines in `~/.zsh.local` or the old config.
  Remove them or lazy-load them (snippet below).
- `oh-my-zsh` or a second `compinit`.
  Remove them. This config already runs one cached `compinit`.
- A managed-device security agent.
  Measure the floor with `hyperfine --warmup 3 'zsh -f -i -c exit'`.
  Whatever that shows is outside this config.
- A huge repo making the prompt slow.
  In `~/.config/starship.toml`, lower `command_timeout`, or set `[git_status] disabled = true`.
  The file is a link into `~/.config/fast-zsh`, so copy it to a real file first if you want to keep the change across updates.

Lazy-load a version manager you cannot drop (put it in `~/.zsh.local`):

```zsh
path=($HOME/.pyenv/shims $path)
pyenv() { unfunction pyenv; eval "$(command pyenv init -)"; pyenv "$@"; }
```

## Moving from nvm

mise reads `.nvmrc` and `.node-version`, so existing projects keep working.

| nvm | mise |
|---|---|
| `nvm install 22` | `mise install node@22` |
| `nvm use 22` | `mise shell node@22`, or `mise use node@22` to pin it in the project |
| `nvm alias default 22` | `mise use -g node@22` |

mise does not install a missing version when you `cd` into a project.
It warns instead, and `mise install` fixes it.
`~/.nvm` can stay on disk.
Delete it only after the user agrees.

## mise says a config is "not trusted"

mise asks for trust before it reads a project's `mise.toml`.
Read the file, then run `mise trust` in that directory.

## Boxes or question marks in the prompt

The default prompt uses plain Unicode (the lightning bolt and arrow) and ASCII git markers, so any font works.
The icon variant (`install.sh --icons`) draws a branch icon that needs a Nerd Font.
A box where the icon belongs means the terminal profile is not using one.
Run `scripts/fonts.sh check` to see which terminal is wrong, and `scripts/fonts.sh apply` to fix Ghostty and cmux.
To go back to the plain prompt, re-run `install.sh` without `--icons`.

A literal `??` in `git status -sb` output is git's marker for an untracked file and is not a font problem.
The same applies to `?`, `!`, `$` and the arrows after the branch name in the prompt: untracked, modified, stashed, ahead or behind.

## Fonts, kerning and anti-aliasing

Nerd Fonts ships every family in variants, and the Homebrew cask installs all of them:

- Nerd Font: icons are drawn wider than one cell and can overlap the next character.
- Nerd Font Mono: every icon fits in one cell. Use this in a terminal.
- Nerd Font Propo: glyph widths vary, which suits UI text and breaks a terminal's grid. Never select it in a terminal.
- The NL families (JetBrainsMonoNL) are the same fonts without programming ligatures.

Installing all variants is correct.
What matters is the family a terminal selects: "JetBrainsMono Nerd Font Mono", or "JetBrainsMonoNL Nerd Font Mono" for no ligatures.
Ghostty 1.2.3 lists only the Mono families in its font list.

A terminal places every character in a fixed-width cell, so kerning (adjusting the gap between letter pairs) does not apply.
Uneven spacing in a terminal comes from one of three things: a Propo font, a spacing slider moved off its default, or a second font used for non-ASCII text.
Keep the spacing settings at their defaults:

| Terminal | Settings to leave at default |
|---|---|
| iTerm | Profiles > Text > Horizontal and Vertical spacing at 100%, "Use a different font for non-ASCII text" off |
| Terminal.app | Profiles > Text > Character spacing and Line spacing at 1 |
| Ghostty, cmux | `adjust-cell-width` and `adjust-cell-height` unset |

Anti-aliasing should stay on in every terminal: "Anti-aliased" in iTerm, "Antialias text" in Terminal.app.
Ghostty and cmux anti-alias by default.
Ghostty's `alpha-blending` defaults to `native` on macOS, which matches the system, so leave it alone.
`linear-corrected` looks nearly identical without dark halos around colored text, and plain `linear` makes dark text thin and light text heavy.
If text looks thin on your display, add `font-thicken = true` (macOS only) to the Ghostty config.

Ligatures: the Mono family has them, the NL family does not.
In Ghostty and cmux, `font-feature = -calt` turns them off.
In iTerm they are Profiles > Text > "Use ligatures".
Terminal.app cannot render them.

Where each terminal reads its font:

- iTerm and Terminal.app keep it in the profile, so set it once by hand (steps print from `fonts.sh apply`).
- Ghostty and cmux share `~/.config/ghostty/config`.
  cmux reads only that file, and uses the first config file it finds ([cmux configuration docs](https://cmux.com/docs/configuration)).
  Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` after it, and that file wins, so keep `font-family` in one place.
  Reload with Cmd-Shift-comma, or `cmux reload-config`.
  Panes that are already open can keep the old font until they are reopened.

## Diffs look wrong after enabling git-delta

`install.sh --git-delta` sets four global git options: `core.pager`, `interactive.diffFilter`, `delta.navigate` and `delta.line-numbers`.
Side-by-side is off by default because it wraps badly in narrow panes.
`gdd` shows one diff side by side.
To undo everything:

```
git config --global --unset core.pager
git config --global --unset interactive.diffFilter
git config --global --remove-section delta
```

## Alt-C does nothing

macOS terminals send a special character for Option unless told otherwise.
iTerm: Profiles > Keys > Left Option key = Esc+.
Ghostty: `macos-option-as-alt = true`.

## Suggestions are invisible or too faint

Set a visible color in `~/.zsh.local`:

```zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
```

Suggestions come from history only.
The plugin's `completion` strategy runs the completion system in the background on keystrokes that have no history match, which is heavier and sometimes glitchy.
To opt in anyway, add `ZSH_AUTOSUGGEST_STRATEGY=(history completion)` to `~/.zsh.local`.

## git reset HEAD^ says "no matches found"

`EXTENDED_GLOB` makes `^` and `#` glob operators, so `HEAD^` is read as a pattern.
This config leaves it off.
If the error appears, something sets it: look for `setopt EXTENDED_GLOB` in `~/.zsh.local` and in the lines other tools added to `~/.zshrc`.
To keep it on, quote the argument (`git reset 'HEAD^'`), or use `HEAD~1`.

## ls -lt prints an error

`ls` is deliberately not aliased to eza.
eza's `-t` selects a timestamp field instead of sorting by time, so an `ls` alias breaks `ls -lt`.
The eza commands are `ll`, `la` and `lt`.
If your old config aliases `ls`, that alias is in the backup directory and in `~/.zsh.local`.

## A tool added lines to ~/.zshrc

That is expected and safe.
`~/.zshrc`, `~/.zshenv` and `~/.zprofile` are ordinary files that load the managed config from `~/.config/fast-zsh`.
Installers such as bun, gcloud, rustup and Homebrew append to them, and updates keep those lines.
Slow ones (nvm, pyenv, conda and similar) show up as warnings in the doctor.

## mise runs before every prompt

mise's default mode runs `mise hook-env` before each prompt, about 12ms, so PATH and `[env]` follow whichever `mise.toml` or `.nvmrc` is in the current directory.
For no per-prompt cost, use shims instead.
Put this in `~/.zshenv`, which updates leave alone:

```zsh
export FAST_ZSH_MISE_SHIMS=1
```

Shims add one extra exec per command, and `[env]` entries from `mise.toml` stop being applied.

## Syntax highlighting stopped working

zsh-syntax-highlighting has to be the last plugin loaded.
If `~/.zsh.local` sources other plugins, add this as its final line:

```zsh
source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
```

## z jumps to the wrong directory

```
zoxide query -ls <fragment>     # candidates and scores
zoxide remove <path>            # drop one entry
zi <fragment>                   # choose interactively
```

These locations are never recorded: `*/.claude/worktrees/*` (Claude Code creates worktrees inside each repo), `*/.cursor/worktrees/*`, `*/.worktrees/*`, `/tmp`, `/private/tmp` and `/private/var/folders`.
Entries recorded before an exclusion existed stay until you run `zoxide remove`.
To exclude another pattern, add to `~/.zsh.local`:

```zsh
export _ZO_EXCLUDE_DIRS="$_ZO_EXCLUDE_DIRS:*-wt-*"
```

## Intel Macs and Linuxbrew

Homebrew lives in `/usr/local` on Intel Macs.
`.zprofile` and `path.zsh` detect `/opt/homebrew`, `/usr/local` and `/home/linuxbrew/.linuxbrew`, so no edits are needed.
The installer targets macOS only.

## A different ZDOTDIR is set

If `ZDOTDIR` is exported, zsh reads its startup files from there and ignores the files in `$HOME`.
Unset it, or copy the three stub files from `$HOME` into that directory.

## An existing prompt framework

Only one prompt can win.
Remove `ZSH_THEME`, powerlevel10k and other `PROMPT=` lines from the old config.
They are in the backup directory and nothing has been deleted.

## Roll back

```
scripts/uninstall.sh
```

It removes the fast-zsh lines from `~/.zshrc`, `~/.zshenv` and `~/.zprofile` and restores the most recent backup.
Lines other tools added to those files are kept, and in that case the backup is left for you to merge by hand.
Pass a backup directory to pick another one.
`~/.zsh.local`, `~/.config/fast-zsh` and the Homebrew packages stay in place.
