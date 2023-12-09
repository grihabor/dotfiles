#!/bin/bash

alias vi="nvim"
alias vim="nvim"
alias vimdiff="nvim -d"

export EDITOR=nvim

if test -z "$NVIM" && test -n "$TMUX"; then
    v -c terminal -c startinsert
fi
