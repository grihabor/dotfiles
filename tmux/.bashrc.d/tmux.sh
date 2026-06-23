#!/bin/bash

# tmux sets TERM for panes itself; overriding it in the shell breaks terminal
# feature detection for kitty and nested terminals.
