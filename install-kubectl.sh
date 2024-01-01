#!/bin/bash

KUBECTL="$HOME/.local/bin/kubectl"
curl -L --output "$KUBECTL" \
	"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x "$KUBECTL"
