# Plugins come from Homebrew (version-pinned, updated by `brew upgrade`, no plugin manager at
# runtime). zsh-syntax-highlighting MUST be sourced last.
_zp=${HOMEBREW_PREFIX:-/opt/homebrew}/share

# History only. The `completion` strategy runs the completion system in the background on every
# keystroke that has no history match, which is heavier and occasionally glitchy.
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
ZSH_AUTOSUGGEST_MANUAL_REBIND=1                 # skip per-prompt widget rebinding (all widgets exist by now)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
[[ -r $_zp/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source $_zp/zsh-autosuggestions/zsh-autosuggestions.zsh

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=300
[[ -r $_zp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source $_zp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset _zp
