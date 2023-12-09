# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
. "$HOME/.cargo/env"

# >>> coursier install directory >>>
export PATH="$PATH:/home/grihabor/.local/share/coursier/bin"
# <<< coursier install directory <<<

# path
export PATH="$PATH:/home/grihabor/bin/google-cloud-sdk/bin"
export PATH="$PATH:/home/grihabor/.npm-packages/bin/"
export PATH="$PATH:/usr/local/go/bin/"
export PATH="$PATH:/home/grihabor/go/bin/"
export PATH="$HOME/lib/apache-maven/apache-maven-3.9.3/bin:$PATH"
# ~/.tmux/plugins
export PATH="$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
# ~/.config/tmux/plugins
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
export PATH="$HOME/projects/flutter/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

