# ~/.zshrc - interactive shells only.
# Modules live in .zsh.d/ and load in a fixed order (plugins last).
# Put personal aliases, PATH additions and secrets in ~/.zsh.local, never in this directory.
#
# Profile startup:  ZSH_PROFILE=1 zsh -i -c exit     Benchmark:  hyperfine --warmup 3 'zsh -i -c exit'

[[ -n $ZSH_PROFILE ]] && zmodload zsh/zprof

# Resolve the real location of this file (follows the symlink from ~/.zshrc).
ZSH_CONFIG_DIR=${${(%):-%x}:A:h}/.zsh.d
ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"

for _module in path env options aliases functions completion tools plugins; do
  [[ -r $ZSH_CONFIG_DIR/$_module.zsh ]] && source "$ZSH_CONFIG_DIR/$_module.zsh"
done
unset _module

# Machine-local and untracked: secrets, personal aliases, per-machine overrides.
[[ -r $HOME/.zsh.local ]] && source "$HOME/.zsh.local"

[[ -n $ZSH_PROFILE ]] && zprof
