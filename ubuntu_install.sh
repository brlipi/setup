#!/bin/bash

# Refresh apt
sudo apt update

if [ $(systemd-detect-virt) = 'none' ]; then
	# Windows x Linux time bs
	timedatectl set-local-rtc 1 --adjust-system-clock

	# GRUB save choice
	sudo sed -Ei 's|^GRUB_DEFAULT=.*$|GRUB_DEFAULT=saved|g ; s|^GRUB_SAVEDEFAULT=.*$|GRUB_SAVEDEFAULT=true|g' /etc/default/grub
	sudo update-grub

	# Wifi dying issue
	sudo apt install -y iw
	sudo echo 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlp2s0", RUN+="/usr/bin/iw dev $name set power_save off"' > /etc/udev/rules.d/81-wifi-powersave.rules 

	# Chromium
	sudo apt install -y chromium
	
	# KeePassXC
	sudo apt install -y keepassxc

	# VPN + token
	sudo apt install -y openconnect p11tool gnutls-bin opensc valgrind
	
	# Fontconfig
	mkdir ~/.config/fontconfig
else
	# WSL only
	if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
		winusername=powershell.exe '$env:UserName'
		ln -s /mnt/c/Users/$winusername/Downloads/share /home/$USER/share
	fi
fi

# Essentials
sudo apt install -y git default-jre unrar ca-certificates curl build-essential oathtool tmux nmap openssl python3-pip zsh luarocks ripgrep fzf gnupg2 gawk htop sshpass

# Symlink python to python3
sudo ln -s /usr/bin/python3 /usr/bin/python

## Docker installation
# Remove old and conflicting stuff
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm /etc/apt/sources.list.d/docker.sources
sudo rm /etc/apt/keyrings/docker.asc

# Setup repo
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

# Run without sudo
sudo groupadd docker
sudo usermod -aG docker $USER
# Should have the same effect as logging back in
# https://stackoverflow.com/a/76889494
exec sg docker newgrp

# fnm for Nodejs
curl -fsSL https://fnm.vercel.app/install | bash -s
# Yarn and TS as global packages
# npm i -g npm updates the package manager
# Also add fnm completions for zsh
source /home/$USER/.bashrc && bash -c 'fnm install --lts ; npm i -g npm yarn typescript ; sudo mkdir -p /usr/share/zsh/site-functions ; fnm completions --shell zsh | sudo tee -a /usr/share/zsh/site-functions/_fnm >/dev/null'

# Linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo -en "\n#Linuxbrew" >> /home/$USER/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/$USER/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

# Brew
brew install fastfetch neovim tree-sitter tree-sitter-cli

# Remove vim
sudo apt remove -y vim

# Symlink vim to nvim
sudo ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vim

## Configuring tools to use XDG Base Directory
# Tmux dir
mkdir ~/.config/tmux
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
sudo cp /etc/wgetrc ~/.config/wgetrc

# Inputrc
mkdir ~/.config/readline
touch ~/.config/inputrc

# For bash
printf "if [ ! -a ~/.config/inputrc ]; then\n\techo '\$include /etc/inputrc' > ~/.config/inputrc;\n\techo 'set completion-ignore-case On' >> ~/.config/inputrc\n\techo 'stty -ixon' >> ~/.config/inputrc\nfi" >> ~/.bashrc

# Gitconfig
touch ~/.config/gitconfig

# Directory-specific gitconfigs
printf "[user]\n\temail = \n\t name = \n\t\n\n[includeIf \"gitdir:~/git/personal/\"]\n\tpath = ~/git/personal/.gitconfig_include_personal\n[includeIf \"gitdir:~/git/work/\"]\n\tpath = ~/git/work/.gitconfig_include_work" | tee -a ~/.config/gitconfig >/dev/null
mkdir -p ~/git/{personal,work}
printf "[user]\n\temail = \n\tname = " | tee -a ~/git/personal/.gitconfig_include_personal >/dev/null
printf "[user]\n\temail = \n\tname = " | tee -a ~/git/work/.gitconfig_include_work >/dev/null


# Docker autocompletion
# By default comes in /usr/share/zsh/vendor-completions/_docker so copying it is also a valid option
# But docker compose completion won't work.
if [ -e /usr/share/zsh/site-functions/_docker ]; then
    # Needs sudo bash -c so redirection is also run as root
    sudo bash -c 'docker completion zsh > /usr/share/zsh/site-functions/_docker'
fi

# Copy SSH Config file and create keys dir
mkdir -p ~/.ssh/keys
chmod 700 ~/.ssh
chmod 700 ~/.ssh/keys
cp ./ssh/ssh_config_template ~/.ssh/config
chmod 600 ~/.ssh/config
