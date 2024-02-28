#!/usr/bin/env bash

# PROMPT COLOURS
readonly RESET='\033[0;0m'
readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'

readonly DOTFILES_CONFIG_DIR="/home/${USERNAME}/.dotfiles/config"

function ask_value() {
    local message=$1
    local default_value=$2
    local value
    local default_value_message=''

    if [[ ! -z "${default_value}" ]]; then
        default_value_message=" (default: ${YELLOW}${default_value}${CYAN})"
    fi

    echo -e "${CYAN}${message}${default_value_message}: ${RESET}" > /dev/tty
    read value < /dev/tty

    if [[ -z "${value}" ]]; then
        value=${default_value}
    fi

    echo "${value}"
}

function block() {
    local color=$1
    local text=$2
    local title_length=${#text}

    echo -en "\n\033[${color}m\033[1;37m    "
    for x in $(seq 1 ${title_length}); do echo -en " "; done;
    echo -en "\033[0m\n"

    echo -en "\033[${color}m\033[1;37m  ${text}  \033[0m\n"
    echo -en "\033[${color}m\033[1;37m    "
    for x in $(seq 1 ${title_length}); do echo -en " "; done;
    echo -en "\033[0m\n\n"
}

function block_error() {
    block "41" "${1}"
}

function block_success() {
    block "42" "${1}"
}

function block_warning() {
    block "43" "${1}"
}

function block_info() {
    block "44" "${1}"
}

function echo_error() {
    echo -e "${RED}${1} ${RESET}" > /dev/tty
}

function echo_success() {
    echo -e "${GREEN}${1} ${RESET}" > /dev/tty
}

function echo_warning() {
    echo -e "${YELLOW}${1} ${RESET}" > /dev/tty
}

function echo_info() {
    echo -e "${CYAN}${1} ${RESET}" > /dev/tty
}

function echo_replace() {
    echo  -e "$1 \r\c" > /dev/tty
}

function trap_exit() {
    if [[ $? -ne 0 ]]; then
        block_error "An error occurred during dotfiles installation."
    fi
}

function install_apt_packages() {
    echo_info "Install APT packages"

    sudo apt update
    sudo apt install -y \
        ansible \
        bat \
        bash-completion \
        compizconfig-settings-manager \
        ffmpeg \
        fonts-powerline \
        git \
        gnupg2 \
        htop \
        httpie \
        imagemagick \
        jq \
        less \
        libavcodec-extra \
        libfuse2 \
        make \
        nano \
        p7zip-full \
        python3-pygments \
        pv \
        ssh \
        stacer \
        ubuntu-restricted-extras \
        unzip \
        unrar \
        zsh \
        --no-install-recommends
}

function install_docker() {
    echo_info "Install Docker & Docker Compose"

    curl -fsSL https://get.docker.com -o install-docker.sh
    sudo sh install-docker.sh
    rm -f install-docker.sh

    sudo usermod -aG docker ${USERNAME}

    echo_info "Install LazyDocker"
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    mkdir -p /home/${USERNAME}/.config/lazydocker
    ln -s ${DOTFILES_CONFIG_DIR}/lazydocker.yml /home/${USERNAME}/.config/lazydocker/config.yml
}

function install_terraform() {
    echo_info "Install Terraform"

    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt-get install terraform
}

function clean_apt() {
    echo_info "Clean APT"

    sudo apt autoremove -y
    sudo apt autoclean -y
    sudo apt clean -y
}

function setup_zsh() {
    echo_info "Setting up zsh"

    chsh -s /bin/zsh
    cd "/home/${USERNAME}"
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    wget -P /home/${USERNAME}/.oh-my-zsh/custom/themes https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    if [[ -f "/home/${USERNAME}/.aliases" ]]; then
        rm /home/${USERNAME}/.aliases
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/aliases /home/${USERNAME}/.aliases


    if [[ -f "/home/${USERNAME}/.dockerfunc" ]]; then
        rm /home/${USERNAME}/.dockerfunc
    fi    
    ln -s ${DOTFILES_CONFIG_DIR}/dockerfunc /home/${USERNAME}/.dockerfunc

    if [[ -f "/home/${USERNAME}/.functions" ]]; then
        rm /home/${USERNAME}/.functions
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/functions /home/${USERNAME}/.functions

    if [[ -f "/home/${USERNAME}/.zsh_profile" ]]; then
        rm /home/${USERNAME}/.zsh_profile
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/zsh_profile /home/${USERNAME}/.zsh_profile

    if [[ -f "/home/${USERNAME}/.zshrc" ]]; then
        rm /home/${USERNAME}/.zshrc
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/zshrc /home/${USERNAME}/.zshrc
}

function setup_nano() {
    echo_info "Setting up nano"

    if [[ -f "/home/${USERNAME}/.nanorc" ]]; then
        rm /home/${USERNAME}/.nanorc
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/nanorc /home/${USERNAME}/.nanorc
}

function setup_git() {
    echo_info "Setting up git"

    if [[ -f "/home/${USERNAME}/.gitignore_global" ]]; then
        rm /home/${USERNAME}/.gitignore_global
    fi    
    ln -s ${DOTFILES_CONFIG_DIR}/gitignore_global /home/${USERNAME}/.gitignore_global

    if [[ -f "/home/${USERNAME}/.gitconfig" ]]; then
        rm /home/${USERNAME}/.gitconfig
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/gitconfig /home/${USERNAME}/.gitconfig
}

function setup_psysh() {
    mkdir -p /home/${USERNAME}/.psysh/config

    # Install psysh
    curl -L https://psysh.org/psysh -o /home/${USERNAME}/.psysh/psysh
    chmod +x /home/${USERNAME}/.psysh/psysh

    # Install PHP french manual
    curl -L http://psysh.org/manual/fr/php_manual.sqlite -o /home/${USERNAME}/.psysh/php_manual.sqlite

    cp ${DOTFILES_CONFIG_DIR}/psysh_config.php /home/${USERNAME}/.psysh/config/config.php
}
