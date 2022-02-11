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

readonly DOTFILES_CONFIG_DIR="/home/${USER}/.dotfiles/config"

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
        make \
        nano \
        python-pygments \
        pv \
        ssh \
        stacer \
        unzip \
        unrar \
        zsh \
        --no-install-recommends
}

function install_docker() {
    echo_info "Install Docker & Docker Compose"

    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    sudo usermod -aG docker ${USERNAME}
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
    cd "/home/${USER}"
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    wget -P /home/${USER}/.oh-my-zsh/custom/themes https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    if [[ -f "/home/${USER}/.aliases" ]]; then
        rm /home/${USER}/.aliases
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/aliases /home/${USER}/.aliases


    if [[ -f "/home/${USER}/.dockerfunc" ]]; then
        rm /home/${USER}/.dockerfunc
    fi    
    ln -s ${DOTFILES_CONFIG_DIR}/dockerfunc /home/${USER}/.dockerfunc

    if [[ -f "/home/${USER}/.functions" ]]; then
        rm /home/${USER}/.functions
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/functions /home/${USER}/.functions

    if [[ -f "/home/${USER}/.zsh_profile" ]]; then
        rm /home/${USER}/.zsh_profile
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/zsh_profile /home/${USER}/.zsh_profile

    if [[ -f "/home/${USER}/.zshrc" ]]; then
        rm /home/${USER}/.zshrc
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/zshrc /home/${USER}/.zshrc
}

function setup_nano() {
    echo_info "Setting up nano"

    if [[ -f "/home/${USER}/.nanorc" ]]; then
        rm /home/${USER}/.nanorc
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/nanorc /home/${USER}/.nanorc
}

function setup_git() {
    echo_info "Setting up git"

    if [[ -f "/home/${USER}/.gitignore_global" ]]; then
        rm /home/${USER}/.gitignore_global
    fi    
    ln -s ${DOTFILES_CONFIG_DIR}/gitignore_global /home/${USER}/.gitignore_global

    if [[ -f "/home/${USER}/.gitconfig" ]]; then
        rm /home/${USER}/.gitconfig
    fi
    ln -s ${DOTFILES_CONFIG_DIR}/gitconfig /home/${USER}/.gitconfig
}
