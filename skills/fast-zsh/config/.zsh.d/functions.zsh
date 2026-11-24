mkcd()     { mkdir -p -- "$1" && cd -- "$1"; }
ports()    { lsof -iTCP -sTCP:LISTEN -nP; }            # what is listening
killport() { local p; p=$(lsof -ti tcp:"$1") && [[ -n $p ]] && kill $p || print -u2 "nothing on :$1"; }
zshprof()  { ZSH_PROFILE=1 zsh -i -c exit; }            # per-function startup profile
zshbench() { hyperfine --warmup 3 'zsh -i -c exit'; }   # wall-clock startup (needs hyperfine)
