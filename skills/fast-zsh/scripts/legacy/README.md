These are the managed dotfiles exactly as shipped in v0.1.0 and v0.2.0, which linked ~/.zshrc, ~/.zshenv and ~/.zprofile into ~/.config/fast-zsh.
install.sh diffs a legacy install's copy against them to find lines other tools appended, and keeps those lines when it migrates to the stub files.
