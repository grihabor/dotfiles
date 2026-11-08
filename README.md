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
