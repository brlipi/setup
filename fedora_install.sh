#!/bin/sh

set -e

# Configuring dnf
sudo echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
sudo echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf >/dev/null


# Enable RPM Fusion repos
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Core DNF plugins repo
sudo dnf install -y dnf-plugins-core

if [ $(systemd-detect-virt) = 'none' ]; then
    # Windows x Linux time bs
    timedatectl set-local-rtc 1

    # GRUB theme
    git clone https://github.com/AdisonCavani/distro-grub-themes.git ~
    sudo mkdir /boot/grub2/themes
    sudo cp -r ~/distro-grub-themes/customize/gigabyte /boot/grub2/themes
    sed -Ei 's|^#GRUB_GFXMODE=1920x1080|GRUB_GFXMODE=1920x1080|g ; s|^GRUB_TERMINAL_OUTPUT="console"|#GRUB_TERMINAL_OUTPUT="console"|g ; s|^GRUB_THEME=.*$|GRUB_THEME=/boot/grub2/themes/gigabyte/theme.txt|g' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    rm -rf distro-grub-themes

    # GRUB save choice
    sed -Ei 's|^GRUB_DEFAULT=.*$|GRUB_DEFAULT=saved|g ; s|^GRUB_SAVEDEFAULT=.*$|GRUB_SAVEDEFAULT=true|g' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    # OBS Studio
    sudo dnf install -y obs-studio xorg-x11-drv-nvidia-cuda

    # QEMU + KVM + virt-manager
    sudo dnf install -y @virtualization

    # DVD protection break (tainted repo, land of the free can't use it)
    sudo dnf install -y rpmfusion-free-release-tainted
    sudo dnf install -y libdvdcss

    # Disk image burning
    sudo dnf install -y brasero
 
    # For mouse configurations
    sudo dnf install -y piper
else
    # WSL only
    if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
        winusername=powershell.exe '$env:UserName'
        ln -s /mnt/c/Users/$winusername/Downloads/share /home/breno/share
    fi
fi

# For Fedora GNOME
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    sudo dnf install -y gnome-tweak-tool chrome-gnome-shell gnome-extensions-app
    # Better video thumbnailing for nautilus
    sudo dnf install -y gstreamer1-libav ffmpegthumbnailer
fi

# Assorted stuff
sudo dnf install -y krita sqlitebrowser qbittorrent dnfdragora keepassxc texlive-scheme-medium flameshot tokei inxi btop timeshift gameconqueror thunderbird nmap vlc openssl foliate retroarch bottles python3-pip

# Wireshark
sudo dnf install -y wireshark
sudo usermod -a -G wireshark ${USER}

# tldr
sudo dnf install -y tldr
tldr -u

# VSCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf install -y code

# Extra browsers
sudo dnf install -y chromium
# Brave browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser


# Flatpak stuff
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y flathub com.spotify.Client com.getpostman.Postman net.pcsx2.PCSX2

# Docker installation
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
# Only takes effect on logout-login or reboot
sudo usermod -aG docker ${USER}

# Rice requirements:
sudo dnf install -y git curl zsh neovim luarocks ripgrep fzf gnupg2 gawk fastfetch tmux alacritty
# Zsh autosuggestions and syntax-highlighting
sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting

# Symlink vim to nvim
sudo ln -s /usr/bin/nvim /usr/bin/vim

# fnm for Nodejs
curl -fsSL https://fnm.vercel.app/install | bash -s
# Yarn and TS as global packages
# npm i -g npm updates the package manager
# Also add fnm completions for zsh
bash -c 'source ~/.bashrc ; fnm install --lts ; npm i -g npm yarn typescript ; fnm completions --shell zsh | sudo tee -a /usr/share/zsh/site-functions/_fnm >/dev/null'

# Rust 🦀
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Install CaskaydiaMono Nerd Font
curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "browser_download_url.*CascadiaMono.zip" | tr -d \" | cut -d: -f2,3 | xargs wget
mkdir -p ~/.local/share/fonts
unzip CascadiaMono.zip -d ~/.local/share/fonts
sudo fc-cache -v
rm CascadiaMono.zip
