---
name: fast-zsh
description: Install, verify and repair the team's fast zsh setup on macOS - starship prompt, zoxide, fzf, mise for node, autosuggestions and syntax highlighting, about 100ms startup. Use when someone asks to set up or speed up their zsh or terminal, reports slow shell startup (nvm, oh-my-zsh, pyenv), mentions starship, zoxide or mise, or asks to fix or check a fast-zsh install.
---

# Fast zsh setup

This skill installs a tested zsh config and repairs it when a machine differs from the one it was built on.
Everything it needs is in this skill's directory: `scripts/` (install, doctor, uninstall), `config/` (the files that get installed) and `references/troubleshooting.md`.
Scripts are idempotent and back up anything they replace to `~/.config-backups/fast-zsh-<timestamp>/`.

## Install

1. Run `scripts/install.sh --dry-run` and read the output.
   It lists what it would install, replace and back up.
2. Ask the user which optional pieces they want, then run `scripts/install.sh` with the matching flags.
   `--icons` swaps in the prompt with a branch icon and installs a Nerd Font.
   It only looks right once the terminal profile uses that font, so walk the user through setting it (steps are printed at the end of the install).
   `--git-delta` makes delta git's pager for colored, line-numbered diffs, and does nothing if `core.pager` is already set.
   `--skip-node` is for users who manage node some other way.
   `--hushlogin` hides the "Last login" banner.
3. Read the doctor report at the end of the install.
   Work through every WARN and FAIL using the `fix:` line under it, and `references/troubleshooting.md` for anything the hint does not cover.
   A warning can be intentional, so show the user the line it points at before you change or delete it.
   Re-run `scripts/doctor.sh` until it reports 0 fail.
4. Port the user's old config.
   The installer lists what it found in the backed-up files (aliases, exports, nvm, pyenv, possible secrets).
   Read those files in the backup directory and move what the user still wants into `~/.zsh.local`.
   Drop the nvm, oh-my-zsh and pyenv init lines, and tell the user mise replaces nvm (`.nvmrc` still works).
5. Ask the user to open a new terminal tab and check the prompt.
   If they chose `--icons`, run `scripts/fonts.sh check` and walk them through any terminal it flags.
   A box where the branch icon should be means that terminal's font is wrong (see troubleshooting).
   If startup feels slow, run `zshprof` and fix the top entry.
6. Offer to customize the look and feel (see Customize below).
7. Report what changed, the backup path, how to roll back (`scripts/uninstall.sh`), and the few habits worth learning: `z <fragment>` to jump to a directory, Ctrl-R for fuzzy history, Ctrl-T for files with a preview, Ctrl-/ to toggle previews.

## Customize

After the install works, offer to customize the look and feel.
Read `references/customize.md`, ask the questions with the AskUserQuestion tool (batches of up to four, with the previews listed there), and apply every answer with `scripts/customize.sh`.
Never hand-edit the user's starship config or Ghostty config to do this, because the script validates what it writes and keeps its changes in blocks that `customize.sh reset` can remove.

For the terminal color theme, send the user to https://terminalcolors.com/themes/ to browse and choose.
Ask for the theme page URL or its name (`<theme>/<variant>`, for example `moonfly/default`), verify it with `scripts/customize.sh theme <theme>/<variant> --check`, then apply it.
Tell the user the clicks the script cannot do (picking the imported preset in iTerm and the imported profile in Terminal.app, and reloading Ghostty and cmux).

## Repair

Run `scripts/doctor.sh`.
It checks tools, the startup files, startup errors, completion permissions, PATH duplicates, node through mise, terminal fonts and startup time, and prints a `fix:` line per problem.
Apply each fix that is clearly safe, ask about the rest, re-run, and stop when it reports 0 fail and the user has seen every warning left.

For font and rendering problems run `scripts/fonts.sh check`, which reads the real settings of Ghostty, cmux, iTerm and Terminal.app.
`scripts/fonts.sh apply` fixes Ghostty and cmux (they share `~/.config/ghostty/config`) and prints the steps for iTerm and Terminal.app, which keep the font in the profile.
Always pick the Mono variant, never a Propo variant, and leave spacing at its defaults.
`references/troubleshooting.md` explains the variants and each rendering setting.
For questions about prompt colors, which modules show (aws, gcloud and others), or the colors of typed commands, read `references/prompt.md`.

On an install made by v0.1 or v0.2, `~/.zshrc` is a symlink into `~/.config/fast-zsh`.
Re-run `scripts/install.sh`: it migrates the file and keeps any lines other tools appended.

## Rules

- Personal changes go in `~/.zsh.local`.
  Files in `~/.config/fast-zsh` are overwritten on every update, so never edit them.
- Never print or paste secrets from the user's old config into chat, and keep `~/.zsh.local` at mode 600.
- Ask before running `sudo`, deleting `~/.nvm`, `~/.pyenv` or `~/.oh-my-zsh`, or changing anything outside the shell config.
- Never delete or rewrite a line of the user's own config just because a check flagged it.
  Show the line, explain the cost, and let the user decide.
- If a fix would help every teammate, tell the user to propose it in the shared repo instead of patching one machine.
- macOS only.
  On Linux, stop and say it is untested.
