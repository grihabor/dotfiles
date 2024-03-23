#!/bin/bash

if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
fi

export PATH="$PATH:$HOME/.local/share/coursier/bin"
export PATH="$PATH:$HOME/bin/google-cloud-sdk/bin"
export PATH="$PATH:$HOME/.npm-packages/bin/"
export PATH="$PATH:/usr/local/go/bin/"
export PATH="$PATH:$HOME/go/bin/"
export PATH="$PATH:$HOME/.luarocks/bin/"
