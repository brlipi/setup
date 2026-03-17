#!/bin/bash

## Configuring tools to use XDG Base Directory
# Tmux dir
mkdir -p ~/.config/tmux
git clone https://github.com/tmux-plugins/tpm $HOME/.config/tmux/plugins/tpm

# Zsh dirs
mkdir -p ~/.cache/zsh/zcompcache
touch ~/.cache/zsh/zcompdump
mkdir -p ~/.local/state/zsh
touch ~/.local/state/zsh/history

# Less
touch ~/.config/lesskey
touch ~/.local/state/lesshst

# Wget
# Default wgetrc missing on Fedora
#sudo cp /etc/wgetrc ~/.config/wgetrc

# Inputrc
mkdir ~/.config/readline
touch ~/.config/inputrc

# For bash
tee -a ~/.bashrc >/dev/null <<EOF
if [ ! -a ~/.config/inputrc ]; then
	echo '\$include /etc/inputrc' > ~/.config/inputrc;
	echo 'set completion-ignore-case On' >> ~/.config/inputrc
	echo 'stty -ixon' >> ~/.config/inputrc
fi
EOF

# Gitconfig
touch ~/.config/gitconfig

# Directory-specific gitconfigs
cat > ~/.config/gitconfig <<EOF
[user]
	email =
	name =

[includeif "gitdir:~/git/personal/"]
	path = ~/git/personal/.gitconfig_include_personal
[includeif "gitdir:~/git/work/"]
	path = ~/git/work/.gitconfig_include_work
EOF

mkdir -p ~/git/{personal,work}
cat > ~/git/personal/.gitconfig_include_personal <<EOF
[user]
	email =
	name =
EOF
cat > ~/git/work/.gitconfig_include_work <<EOF
[user]
	email =
	name =
EOF

# Copy SSH Config file and create keys dir
mkdir -p ~/.ssh/keys
chmod 700 ~/.ssh
chmod 700 ~/.ssh/keys
cp ./ssh/ssh_config_template ~/.ssh/config
chmod 600 ~/.ssh/config

# Add user to wireshark group
sudo usermod -a -G wireshark ${USER}

# Setup docker
sudo systemctl enable --now docker

# Run without sudo
sudo groupadd docker
sudo usermod -aG docker $USER
# Should have the same effect as logging back in
# https://stackoverflow.com/a/76889494
exec sg docker newgrp
# Docker autocompletion
# By default comes in /usr/share/zsh/vendor-completions/_docker so copying it is also a valid option
# But docker compose completion won't work.
if [ -e /usr/share/zsh/site-functions/_docker ]; then
    # Needs sudo bash -c so redirection is also run as root
    sudo bash -c 'docker completion zsh > /usr/share/zsh/site-functions/_docker'
fi

# Remove vim and set set nvim as vi[m]
sudo dnf remove -y vim-minimal
sudo ln -s /usr/sbin/nvim /usr/sbin/vim
sudo ln -s /usr/sbin/nvim /usr/sbin/vi

# Set share dir (WSL only)
if [[ $(systemd-detect-virt) != 'wsl' ]]; then
    winusername=powershell.exe '$env:UserName'
    ln -s /mnt/c/Users/$winusername/Downloads/share /home/$USER/share
fi
