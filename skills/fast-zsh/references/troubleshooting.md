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
The installer adds the font with `brew install --cask font-jetbrains-mono-nerd-font`, and the terminal still has to select it:

- iTerm: Settings > Profiles > Text > Font, then pick "JetBrainsMono Nerd Font Mono".
- Ghostty: add `font-family = "JetBrainsMono Nerd Font Mono"` to `~/.config/ghostty/config`.
  On macOS Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`, which overrides the first file.
  Reload with Cmd-Shift-comma or restart.

To go back to the plain prompt, re-run `install.sh` without `--icons`.

A literal `??` in `git status -sb` output is git's marker for an untracked file and is not a font problem.
The same applies to `?`, `!`, `$` and the arrows after the branch name in the prompt: untracked, modified, stashed, ahead or behind.

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

Agent-managed worktrees are excluded already.
To exclude another pattern, add to `~/.zsh.local`:

```zsh
export _ZO_EXCLUDE_DIRS="$_ZO_EXCLUDE_DIRS:*-wt-*"
```

## Intel Macs and Linuxbrew

Homebrew lives in `/usr/local` on Intel Macs.
`.zprofile` and `path.zsh` detect `/opt/homebrew`, `/usr/local` and `/home/linuxbrew/.linuxbrew`, so no edits are needed.
The installer targets macOS only.

## A different ZDOTDIR is set

If `ZDOTDIR` is exported, zsh reads its startup files from there and ignores the links in `$HOME`.
Unset it, or install the links into that directory.

## An existing prompt framework

Only one prompt can win.
Remove `ZSH_THEME`, powerlevel10k and other `PROMPT=` lines from the old config.
They are in the backup directory and nothing has been deleted.

## Roll back

```
scripts/uninstall.sh
```

It removes the links and restores the most recent backup.
Pass a backup directory to pick another one.
`~/.zsh.local`, `~/.config/fast-zsh` and the Homebrew packages stay in place.
