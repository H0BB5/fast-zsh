# Customizing the prompt and colors

## Where the prompt settings live

Starship reads the file named by `$STARSHIP_CONFIG`, or `~/.config/starship.toml` when that is unset.
The installer links `~/.config/starship.toml` to `~/.config/fast-zsh/starship.toml`, and every update overwrites that file.
To keep your own version, copy it somewhere else and point starship at the copy from `~/.zsh.local`:

```
cp ~/.config/fast-zsh/starship.toml ~/.config/starship-mine.toml
echo 'export STARSHIP_CONFIG=$HOME/.config/starship-mine.toml' >> ~/.zsh.local
```

Open a new tab and edit `starship-mine.toml` from then on.
Updates never touch it.

## How a config is built

The top-level `format` string lists the modules in the order they print, for example `$directory$git_branch$git_status$character`.
Only modules named in `format` appear.
Each module has its own table, such as `[git_branch]`, with options like `style`, `symbol`, `format` and `disabled`.
Inside a module's `format`, `[text](style)` colors text, `$variable` inserts a value, and `( ... )` groups a part that disappears when its variables are empty.

Commands that show what is happening:

```
starship explain                   # every module in the current prompt and why it shows
starship print-config git_branch   # the effective settings of one module
starship module git_branch         # render one module on its own
starship preset --list             # ready-made configs
```

## Colors and styles

Color names are black, red, green, blue, purple, cyan, white and yellow, plus a `bright-` version of each.
There is no color called "magenta".
Starship ignores a name it does not know, silently, and the text prints with no color at all.
The doctor checks for this.

Modifiers are `bold`, `italic`, `underline`, `dimmed` and `inverted`.
A 256-color number (`208`) or a hex value (`fg:#ff8800`, `bg:#222222`) also works.
Combine them with spaces:

```toml
[git_branch]
style = "bold fg:#ff8800"

[directory]
style = "bold cyan"

[character]
success_symbol = "[⚡➜](bold green) "
error_symbol = "[⚡➜](bold red) "
```

Named colors come from the terminal's palette, so "purple" looks different in each theme.
Hex values look the same everywhere.

## Git markers

After the branch, the prompt shows `$` for a stash, `!` for modified files, `?` for untracked files, and arrows for ahead or behind.
Each marker is an option of `[git_status]`, and `${count}` adds the number of files:

```toml
[git_status]
modified = "!${count}"
untracked = "?${count}"
stashed = ""
```

That prints `!3?2` for three modified and two untracked files, and hides the stash marker.

## Extra modules on another machine

A machine without this config uses starship's default `format`, which includes dozens of modules and shows the cloud ones as soon as the tools are configured:

- `on ☁️  (us-east-1)` is the `aws` module: profile and region, from `~/.aws/config` or `AWS_REGION`.
- `on ☁️  name@example.com(us-west1)` is the `gcloud` module: account, domain and region, from `~/.config/gcloud`.

This config sets an explicit `format`, so only the modules it names print, and a machine using it shows neither.
On a machine you have not installed it on, hide them:

```toml
[aws]
disabled = true

[gcloud]
disabled = true
```

Or keep them and trim what they show.
The gcloud module prints your account email, so a project-only format is safer on a shared screen:

```toml
[gcloud]
format = "[$project]($style) "

[aws]
format = "[$profile]($style) "
```

To add a module to this config instead, append it to `format`, for example `$aws` after `$git_status`.

## Colors of what you type

The colors on the command line as you type come from zsh-syntax-highlighting, which is separate from the prompt.
Override its styles in `~/.zsh.local`, which loads after the plugin:

```zsh
ZSH_HIGHLIGHT_STYLES[command]='fg=208,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=51'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=201'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
```

Other keys: `function`, `precommand`, `reserved-word`, `commandseparator`, `redirection`, `globbing`, `assign` and `double-quoted-argument`.
Values take a color name or a number from 0 to 255 after `fg=` or `bg=`, plus `bold` and `underline`, separated by commas.
The grey suggestion text has its own setting:

```zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
```

## Icons and fonts

The default prompt uses plain Unicode and works in any font.
`install.sh --icons` switches to a variant with a branch icon, which needs a Nerd Font in the terminal.
`troubleshooting.md` explains the font variants and the per-terminal settings, and `scripts/fonts.sh check` reports what each terminal is using.
