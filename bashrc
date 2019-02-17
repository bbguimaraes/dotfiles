# If not running interactively, don't do anything
[[ $- != *i* ]] && return
[[ -f /etc/bash.bashrc ]] && . /etc/bash.bashrc
[[ -f /etc/bashrc ]] && . /etc/bashrc

eval "$(dircolors)"
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '
