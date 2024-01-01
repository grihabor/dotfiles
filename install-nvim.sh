#!/bin/bash

git clone https://mpr.makedeb.org/neovim /tmp/neovim
(
	cd /tmp/neovim/ || exit
	makedeb -si
)
