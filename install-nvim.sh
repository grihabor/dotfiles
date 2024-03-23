#!/bin/bash

NVIM_VERSION=${1:-v0.9.5}
sudo apt install cmake lua5.4 luarocks
luarocks install --local lpeg
git clone --depth 1 --branch "${NVIM_VERSION}" https://github.com/neovim/neovim /tmp/neovim
(
    cd /tmp/neovim/ || exit
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
)
