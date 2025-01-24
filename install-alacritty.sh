#!/bin/bash

sudo apt update &&
    sudo apt install libfontconfig1-dev &&
    cargo install alacritty &&
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $HOME/.cargo/bin/alacritty 1 &&
    sudo update-alternatives --set x-terminal-emulator $HOME/.cargo/bin/alacritty
