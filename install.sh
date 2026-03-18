#!/bin/bash

update_existing_packages() {
    sudo dnf update -y
}

configure_dnf() {
    sudo echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
    sudo echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
}

enable_rpm_fusion() {
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

add_docker_repo() {
    sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
}

main() {
    update_existing_packages
    configure_dnf
    enable_rpm_fusion
    add_docker_repo

    if [[ $(systemd-detect-virt) == 'wsl' ]]; then
        ./wsl_fedora_install.sh
    else
        ./fedora_install.sh
    fi
}

main
