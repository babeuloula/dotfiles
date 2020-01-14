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

check_is_sudo() {
    if [[ "${EUID}" -ne 0 ]]; then
        block_error "Please run as root."
        exit 1
    fi
}

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

function trap_exit() {
    if [[ $? -ne 0 ]]; then
        block_error "Une erreur est survenue lors de l'installation du dotfile."
    fi
}

function install_apt_packages() {
    echo_info "Install APT packages:"

    apt install -y \
        compizconfig-settings-manager \
        dia \
        firefox \
        git \
        gitkraken \
        google-chrome-stable \
        bat \
        htop \
        httpie \
        imagemagick \
        make \
        meld \
        mysql-workbench \
        nano \
        teamviewer \
        tilix \
        fonts-powerline \
        zsh \
        gnome-tweaks \
        variety
}

function install_snap_packages() {
    echo_info "Install SNAP packages:"

    snap install \
        datagrip \
        gimp \
        mailspring \
        phpstorm \
        postman \
        skype \
        slack \
        spotify \
        sublime-text \
        termius-app \
        tldr \
        vlc \
        indicator-sensors
}

function install_docker() {
    echo_info "Install Docker & Docker Compose:"

    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io

    curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    usermod -a -G docker ${USERNAME}
}

function setup_tilix() {
    echo_info "Setting up Tilix:"

    dconf load /com/gexperts/Tilix/ < ~/.dotfiles/config/tilix.conf
}

function setup_zsh() {
    echo_info "Setting up zsh:"

    chsh -s /bin/zsh
    cd ~/
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    wget -P ~/.oh-my-zsh/custom/themes https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme

    cp ~/.dotfiles/config/.aliases ~/.aliases
    cp ~/.dotfiles/config/.dockerfunc ~/.dockerfunc
    cp ~/.dotfiles/config/.zsh_profile ~/.zsh_profile
    cp ~/.dotfiles/config/.zshrc ~/.zshrc
}

function setup_nano() {
    echo_info "Setting up nano:"

    cp ~/.dotfiles/config/.nanorc ~/.nanorc
}

function setup_git() {
    echo_info "Setting up git:"

    cp ~/.dotfiles/config/.gitignore_global ~/.gitignore_global
    cp ~/.dotfiles/config/.gitconfig ~/.gitconfig
}
