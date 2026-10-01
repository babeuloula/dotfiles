#!/usr/bin/env bash
# Steps for every Linux profile (desktop and server)

function install_apt_packages() {
    echo_info "Install APT packages"

    local packages=(
        ansible
        bat
        bash-completion
        curl
        ffmpeg
        fzf
        git
        gnupg2
        htop
        httpie
        imagemagick
        jq
        less
        make
        nano
        p7zip-full
        pv
        python3-pygments
        rclone
        ssh
        tree
        unrar
        unzip
        wget
        zsh
    )

    if [[ "${DOTFILES_PROFILE}" == "linux-desktop" ]]; then
        add_apt_repo google-chrome https://dl.google.com/linux/linux_signing_key.pub \
            "deb [arch=amd64 SIGNED_BY] https://dl.google.com/linux/chrome/deb/ stable main"
        add_apt_repo signal-desktop https://updates.signal.org/desktop/apt/keys.asc \
            "deb [arch=amd64 SIGNED_BY] https://updates.signal.org/desktop/apt xenial main"

        # Accept the Microsoft fonts EULA up front, otherwise apt waits for an answer
        echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

        packages+=(
            compizconfig-settings-manager
            dia
            firefox
            fonts-powerline
            gnome-tweaks
            google-chrome-stable
            libavcodec-extra
            libfuse2
            meld
            pavucontrol
            signal-desktop
            snapd
            stacer
            tilix
            ubuntu-restricted-extras
            variety
        )
    fi

    apt_update
    apt_install "${packages[@]}"
}

function install_docker() {
    echo_info "Install Docker & Docker Compose"

    if ! command -v docker > /dev/null; then
        local tmp
        tmp=$(mktemp)
        curl -fsSL https://get.docker.com -o "${tmp}"
        sudo sh "${tmp}"
        rm -f "${tmp}"
    fi

    sudo usermod -aG docker "$(id -un)"
}

function install_lazydocker() {
    echo_info "Install LazyDocker"

    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    link_config lazydocker.yml "$HOME/.config/lazydocker/config.yml"
}

function install_terraform() {
    echo_info "Install Terraform"

    local codename arch
    # shellcheck disable=SC1091
    codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")
    arch=$(dpkg --print-architecture)

    # A brand new Ubuntu release is not published right away: fall back to the last LTS
    if ! curl -fsI "https://apt.releases.hashicorp.com/dists/${codename}/Release" > /dev/null; then
        echo_warning "  Pas de dépôt HashiCorp pour ${codename}, utilisation de noble"
        codename="noble"
    fi

    add_apt_repo hashicorp https://apt.releases.hashicorp.com/gpg \
        "deb [arch=${arch} SIGNED_BY] https://apt.releases.hashicorp.com ${codename} main"

    apt_update
    apt_install terraform
}

function clean_apt() {
    echo_info "Clean APT"

    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    sudo apt-get clean -y
}
