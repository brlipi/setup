#!/bin/bash

dnf_install=(sudo dnf install -y)

install_core_dnf_plugins() {
    dnf_install+=("dnf-plugins-core")
}

install_python3_pip() {
    dnf_install+=("python3-pip")
}

install_other_extractors() {
    dnf_install+=("unrar" "p7zip" "p7zip-plugins")
}

install_net_tools() {
    dnf_install+=("bind-utils" "nmap" "openssl")
}

install_tops() {
    dnf_install+=("htop" "btop")
}

install_wireshark() {
    dnf_install+=("wireshark")
}

install_docker() {
    dnf_install+=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
}

install_essentials() {
    dnf_install+=("curl" "git" "neovim" "zsh" "luarocks" "ripgrep" "fzf" "gnupg2" "gawk" "fastfetch" "tmux" "fd-find" "zsh-autosuggestions" "zsh-syntax-highlighting" "oathtool" "sshpass")
}

set_all_dnf_packages() {
    install_core_dnf_plugins
    install_python3_pip
    install_other_extractors
    install_net_tools
    install_tops
    install_wireshark
    install_docker
    install_essentials
}

install_fnm_and_lts_node() {
    curl -fsSL https://fnm.vercel.app/install | bash -s
    # Yarn and TS as global packages
    # npm i -g npm updates the package manager
    # Also add fnm completions for zsh
    source /home/$USER/.bashrc && bash -c 'fnm install --lts ; npm i -g npm yarn typescript ; fnm completions --shell zsh | sudo tee -a /usr/share/zsh/site-functions/_fnm >/dev/null'
}


main() {
    set_all_dnf_packages
    "${dnf_install[@]}"

    install_fnm_and_lts_node
}

main
