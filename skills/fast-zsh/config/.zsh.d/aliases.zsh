# Navigation / listing
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
fi

# Git
alias g=git
(( $+commands[lazygit] )) && alias lg=lazygit
alias gs='git status -sb' gd='git diff' gds='git diff --staged'
alias ga='git add' gaa='git add .'
alias gc='git commit -m' gca='git commit -am'
alias gp='git push' gpl='git pull --rebase --autostash'
alias gsw='git switch' gb='git branch'
alias gl='git log --oneline --graph --decorate -20'
(( $+commands[delta] )) && alias gdd='git -c delta.side-by-side=true diff'   # wide side-by-side diff

# Misc
alias reload='exec zsh'
(( $+commands[brew] )) && alias bup='brew update && brew upgrade && brew cleanup'
