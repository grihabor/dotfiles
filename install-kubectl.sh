#!/bin/bash

curl -L --output $HOME/.local/bin/kubectl \
    "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x $HOME/.local/bin/kubectl
