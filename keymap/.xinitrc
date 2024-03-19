#!/bin/sh

# shellcheck source=/dev/null
[ -f /etc/xprofile ] && . /etc/xprofile
# shellcheck source=/dev/null
[ -f ~/.xprofile ] && . ~/.xprofile

# invoke global X session script
. /etc/X11/Xsession
