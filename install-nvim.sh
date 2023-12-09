#!/bin/bash

PWD=$(pwd)
git clone https://mpr.makedeb.org/neovim /tmp/neovim
cd /tmp/neovim/
makedeb -si
cd $PWD
