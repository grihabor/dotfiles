# List of config files

Install git pre-commit hook
```bash
./install.py
```

Install neovim config
```bash
stow nvim
```

Install system files (target `/`, needs sudo)
```bash
sudo stow -t / display-gamma-reset
```

Install Google Chrome profile-routing wrapper
```bash
stow google-chrome
xdg-settings set default-web-browser google-chrome-wrapper.desktop
sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /home/grihabor/.local/bin/google-chrome-wrapper 100
sudo update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /home/grihabor/.local/bin/google-chrome-wrapper 100
```

Mount external disk at `/mnt/docker` and point Docker's data-root at it
(systemd mount unit + udisks ignore rule). Edit the disk UUID in
`docker-mount/etc/` files to match `lsblk -f`, then stow and activate:
```bash
sudo stow -t / docker-mount
sudo systemctl daemon-reload
sudo udevadm control --reload
sudo systemctl enable --now mnt-docker.mount
sudo systemctl restart docker
```
