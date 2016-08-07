[[ -f ~/.bashrc ]] && . ~/.bashrc
export VISUAL=vim
export EDITOR=vim
export PATH=${PATH+$PATH:}$HOME/.local/bin
alias c='bc -ql'
alias d='xargs -n 1 curl -LO -C -'
