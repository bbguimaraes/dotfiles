# If not running interactively, don't do anything
[[ $- != *i* ]] && return
. /etc/bashrc

eval "$(dircolors)"
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '
