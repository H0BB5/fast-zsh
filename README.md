# fast-zsh

A zsh setup for macOS that starts in about 100ms.
It replaces nvm and a plugin manager with mise and Homebrew-installed plugins, and caches every tool's init code.
The same repo is a Claude Code plugin, so an agent can install it, check it and fix the differences between machines.

## Install

With Claude Code, as a plugin:

```
/plugin marketplace add H0BB5/fast-zsh
/plugin install fast-zsh@fast-zsh
```

Then ask Claude to "set up fast-zsh".

With Claude Code, as a plain skill:

```
git clone https://github.com/H0BB5/fast-zsh.git
cp -R fast-zsh/skills/fast-zsh ~/.claude/skills/
```

Without Claude:

```
git clone https://github.com/H0BB5/fast-zsh.git
cd fast-zsh
./install.sh --dry-run     # shows what would change
./install.sh
```

Options, all off by default:

```
./install.sh --icons        # branch icon in the prompt, installs a Nerd Font (set it in your terminal)
./install.sh --git-delta    # git pages diffs through delta
./install.sh --skip-node    # leave node alone
./install.sh --hushlogin    # hide the "Last login" banner
```

The installer backs up every file it replaces to `~/.config-backups/fast-zsh-<timestamp>/`.
It can be re-run at any time to update.
When it finishes it runs the doctor, and `skills/fast-zsh/scripts/doctor.sh` runs it again whenever you want.

## What it installs

Homebrew packages: starship, zoxide, eza, fd, fzf, bat, mise, hyperfine, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions.
The managed config in `~/.config/fast-zsh/`, loaded by short real files at `~/.zshrc`, `~/.zshenv` and `~/.zprofile`.
Installers like bun, gcloud and rustup can keep appending to those three files, and updates keep what they add.
A link from `~/.config/starship.toml` to the prompt config.
A global node through mise, with `.nvmrc` and `.node-version` support switched on.
An empty `~/.zsh.local` for your own aliases, PATH entries and secrets.

## Daily use

| Keys and commands | Effect |
|---|---|
| `z foo`, `zi foo` | Jump to the best matching directory you have visited, or pick from a list |
| Ctrl-R | Fuzzy search the shared 200,000-line history |
| Ctrl-T, Alt-C | Fuzzy-pick a file path, or a directory to cd into, with a file or tree preview |
| Ctrl-/ | Toggle the preview pane (in Ctrl-R it shows the full command) |
| Right arrow | Accept the grey suggestion |
| `ll`, `la`, `lt` | eza listings, with git status and a two-level tree (`ls` itself is untouched, so `ls -lt` still works) |
| `gs`, `gd`, `gp`, `gpl`, `gl`, `lg` | git status, diff, push, pull --rebase, log, lazygit |
| `gdd` | Side-by-side diff through delta (when delta is installed) |
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

The prompt has two lines: directory, branch and git status on top, the input line below.
Branch names longer than 36 characters are cut with an ellipsis.
The default needs no special font.
`./install.sh --icons` adds a branch icon, which needs a Nerd Font set in the terminal profile.
`skills/fast-zsh/references/troubleshooting.md` has the steps for iTerm and Ghostty.

Starship presets are one command away.
Write them to your own file and point starship at it, so updates never overwrite it:

```
starship preset tokyo-night -o ~/.config/starship-mine.toml
echo 'export STARSHIP_CONFIG=$HOME/.config/starship-mine.toml' >> ~/.zsh.local
```

Presets that draw icons or colored segments need a Nerd Font too.
`skills/fast-zsh/references/prompt.md` covers colors, the git markers, hiding or trimming modules such as aws and gcloud, and the colors of what you type.

## Terminal fonts

```
skills/fast-zsh/scripts/fonts.sh check     # read-only report for Ghostty, cmux, iTerm and Terminal.app
skills/fast-zsh/scripts/fonts.sh apply     # writes font-family for Ghostty and cmux
```

Use the Mono variant, "JetBrainsMono Nerd Font Mono", in every terminal.
Never select a Propo variant, because its glyph widths vary and break the terminal's grid.
Kerning does not apply on a grid, so leave the spacing settings at their defaults and keep anti-aliasing on.
`fonts.sh check` flags a Propo font, a non-Mono Nerd Font, off-default spacing and disabled anti-aliasing, and the doctor includes it.
iTerm and Terminal.app keep their font in the profile, so `apply` prints the exact steps for them.
`skills/fast-zsh/references/troubleshooting.md` explains the variants and each rendering setting.

## mise and the prompt hook

mise runs a small command before every prompt (about 12ms) so node follows the `.nvmrc` or `mise.toml` in the current directory.
To pay nothing per prompt, put `export FAST_ZSH_MISE_SHIMS=1` in `~/.zshenv` and mise switches to shims.

## Update and roll back

Pull the repo (or update the plugin) and re-run the installer.
`skills/fast-zsh/scripts/uninstall.sh` removes the fast-zsh lines and restores your previous files, keeping anything other tools appended.
Installs from v0.1 and v0.2 linked those three files into `~/.config/fast-zsh`, and re-running the installer migrates them without losing lines other tools added.

## Repository layout

```
.claude-plugin/        plugin and marketplace manifests
install.sh             wrapper for skills/fast-zsh/scripts/install.sh
skills/fast-zsh/
  SKILL.md             instructions the agent follows
  scripts/             install.sh, doctor.sh, fonts.sh, uninstall.sh (legacy/ holds v0.1 baselines for migration)
  config/              the files that get installed (starship.toml, starship-icons.toml, zsh modules)
  references/          troubleshooting.md, prompt.md (prompt, colors, syntax highlighting)
```

Changes that every teammate should get belong in `skills/fast-zsh/config`, through a pull request.
Changes for one machine belong in that machine's `~/.zsh.local`.
