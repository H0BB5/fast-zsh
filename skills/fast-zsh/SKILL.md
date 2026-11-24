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
   Fix every WARN and FAIL using the `fix:` line under it, and `references/troubleshooting.md` for anything the hint does not cover.
   Re-run `scripts/doctor.sh` until it reports 0 fail.
4. Port the user's old config.
   The installer lists what it found in the backed-up files (aliases, exports, nvm, pyenv, possible secrets).
   Read those files in the backup directory and move what the user still wants into `~/.zsh.local`.
   Drop the nvm, oh-my-zsh and pyenv init lines, and tell the user mise replaces nvm (`.nvmrc` still works).
5. Ask the user to open a new terminal tab and check the prompt.
   If they chose `--icons` and see a box where the branch icon should be, the terminal font is wrong (see troubleshooting).
   If startup feels slow, run `zshprof` and fix the top entry.
6. Report what changed, the backup path, how to roll back (`scripts/uninstall.sh`), and the few habits worth learning: `z <fragment>` to jump to a directory, Ctrl-R for fuzzy history, Ctrl-T for files with a preview, Ctrl-/ to toggle previews.

## Repair

Run `scripts/doctor.sh`.
It checks tools, links, startup errors, completion permissions, PATH duplicates, node through mise and startup time, and prints a `fix:` line per problem.
Apply the fix, re-run, and stop when it reports 0 fail.

## Rules

- Personal changes go in `~/.zsh.local`.
  Files in `~/.config/fast-zsh` are overwritten on every update, so never edit them.
- Never print or paste secrets from the user's old config into chat, and keep `~/.zsh.local` at mode 600.
- Ask before running `sudo`, deleting `~/.nvm`, `~/.pyenv` or `~/.oh-my-zsh`, or changing anything outside the shell config.
- If a fix would help every teammate, tell the user to propose it in the shared repo instead of patching one machine.
- macOS only.
  On Linux, stop and say it is untested.
