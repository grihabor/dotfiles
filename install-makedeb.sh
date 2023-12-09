#!/bin/bash

# https://askubuntu.com/questions/1391230/how-to-install-packages-from-mpr-in-ubuntu

# Add the signing key
wget -qO - 'https://proget.hunterwittenborn.com/debian-feeds/makedeb.pub' | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg &> /dev/null

# Add the repository
echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.hunterwittenborn.com/ makedeb main' | \
sudo tee /etc/apt/sources.list.d/makedeb.list

# Update the index
sudo apt update

# Install makedeb
sudo apt install makedeb

