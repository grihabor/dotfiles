#!/bin/bash

# See https://askubuntu.com/questions/372849/what-does-debian-chrootdebian-chroot-do-in-my-terminal-prompt
# shellcheck disable=SC2154
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
