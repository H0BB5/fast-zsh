# fast-zsh

A zsh setup for macOS that starts in about 100ms.
It replaces nvm and a plugin manager with mise and Homebrew-installed plugins, and caches every tool's init code.
The same repo is a Claude Code plugin, so an agent can install it, check it and fix the differences between machines.

## Install

With Claude Code, as a plugin:

```
/plugin marketplace add <this repo's git URL or local path>
/plugin install fast-zsh@fast-zsh
```

Then ask Claude to "set up fast-zsh".

With Claude Code, as a plain skill:

```
cp -R skills/fast-zsh ~/.claude/skills/
```

Without Claude:

```
./install.sh --dry-run     # shows what would change
./install.sh
```

The installer backs up every file it replaces to `~/.config-backups/fast-zsh-<timestamp>/`.
It can be re-run at any time to update.
When it finishes it runs the doctor, and `skills/fast-zsh/scripts/doctor.sh` runs it again whenever you want.

## What it installs

Homebrew packages: starship, zoxide, eza, fd, fzf, mise, hyperfine, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions.
Links from `~/.zshrc`, `~/.zshenv`, `~/.zprofile` and `~/.config/starship.toml` into `~/.config/fast-zsh/`.
A global node through mise, with `.nvmrc` and `.node-version` support switched on.
An empty `~/.zsh.local` for your own aliases, PATH entries and secrets.

## Daily use

| Keys and commands | Effect |
|---|---|
| `z foo`, `zi foo` | Jump to the best matching directory you have visited, or pick from a list |
| Ctrl-R | Fuzzy search the shared 200,000-line history |
| Ctrl-T, Alt-C | Fuzzy-pick a file path, or a directory to cd into |
| Right arrow | Accept the grey suggestion |
| `ll`, `la`, `lt` | eza listings, with git status and a two-level tree |
| `gs`, `gd`, `gp`, `gpl`, `gl`, `lg` | git status, diff, push, pull --rebase, log, lazygit |
| `mkcd`, `ports`, `killport 3000` | Make and enter a directory, list listeners, stop one |
| `reload`, `zshprof`, `zshbench` | Restart zsh, profile startup, time startup |

zoxide starts empty and learns from the directories you enter.
Seed it with `zoxide add <dir>` for your main project folders.

mise replaces nvm.
`mise use -g node@22` sets the default, `mise install` fetches the versions a project's `.nvmrc` asks for.

## Customize

Put your own configuration in `~/.zsh.local`.
It loads last, so it overrides anything here, and it is never touched by an update.
Files under `~/.config/fast-zsh` are overwritten on update, so do not edit them.

Prompt presets are one command away:

```
starship preset --list
starship preset tokyo-night -o ~/.config/starship.toml   # replaces the link with a real file
```

The prompt needs no special font.
Presets that draw icons need a Nerd Font in your terminal profile, and `references/troubleshooting.md` has the steps.

## Update and roll back

Pull the repo (or update the plugin) and re-run the installer.
`skills/fast-zsh/scripts/uninstall.sh` removes the links and restores your previous files.

## Repository layout

```
.claude-plugin/        plugin and marketplace manifests
install.sh             wrapper for skills/fast-zsh/scripts/install.sh
skills/fast-zsh/
  SKILL.md             instructions the agent follows
  scripts/             install.sh, doctor.sh, uninstall.sh
  config/              the files that get installed
  references/          troubleshooting guide
```

Changes that every teammate should get belong in `skills/fast-zsh/config`, through a pull request.
Changes for one machine belong in that machine's `~/.zsh.local`.
