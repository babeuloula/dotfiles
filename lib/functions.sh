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

    sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

    sudo apt update
    sudo apt install -y \
        bash-completion \
        compizconfig-settings-manager \
        dia \
        firefox \
        fonts-powerline \
        git \
        gnome-tweaks \
        google-chrome-stable \
        htop \
        httpie \
        imagemagick \
        jq \
        less \
        make \
        meld \
        mysql-workbench \
        nano \
        python-pygments \
        rclone \
        ssh \
        tilix \
        unzip \
        unrar \
        variety \
        zsh \
        --no-install-recommends
}

function install_snap_packages() {
    echo_info "Install SNAP packages"

    sudo snap install \
        gimp \
        gitkraken \
        mailspring \
        postman \
        spotify \
        termius-app \
        tldr \
        vlc \
        indicator-sensors

    sudo snap install --classic datagrip
    sudo snap install --classic discord
    sudo snap install --classic phpstorm
    sudo snap install --classic skype
    sudo snap install --classic slack
    sudo snap install --classic sublime-text
    sudo snap install --classic ngrok
}

function install_deb_packages() {
    echo_info "Install DEB packages:"

    echo_replace "${GREEN} - Boost Note... ${RESET}"
    readonly BOOSTNOTE_DEB="boostnote_0.14.0_amd64.deb"
    wget -q "https://github.com/BoostIO/boost-releases/releases/download/v0.14.0/${BOOSTNOTE_DEB}"
    sudo dpkg -i ${BOOSTNOTE_DEB}
    rm ${BOOSTNOTE_DEB}
    echo_success " - Boost Note OK"

    echo_replace "${GREEN} - RcloneTray... ${RESET}"
    readonly RCLONETRAY_DEB="rclonetray_1.0.0_amd64.deb"
    wget -q "https://github.com/dimitrov-adrian/RcloneTray/releases/download/v1.0.0/${RCLONETRAY_DEB}"
    sudo dpkg -i ${RCLONETRAY_DEB}
    rm ${RCLONETRAY_DEB}
    echo_success " - RcloneTray OK"
}

function install_docker() {
    echo_info "Install Docker & Docker Compose"

    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    sudo usermod -aG docker ${USERNAME}
}

function clean_apt() {
    echo_info "Clean APT"

    sudo apt autoremove -y
    sudo apt autoclean -y
    sudo apt clean -y
}

function setup_tilix() {
    echo_info "Setting up Tilix"

    dconf load /com/gexperts/Tilix/ < ${DOTFILES_CONFIG_DIR}/tilix.conf
}

function setup_zsh() {
    echo_info "Setting up zsh"

    sudo chsh -s /bin/zsh
    cd "/home/${USERNAME}"
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    wget -P /home/${USERNAME}/.oh-my-zsh/custom/themes https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    cp ${DOTFILES_CONFIG_DIR}/aliases /home/${USERNAME}/.aliases
    cp ${DOTFILES_CONFIG_DIR}/dockerfunc /home/${USERNAME}/.dockerfunc
    cp ${DOTFILES_CONFIG_DIR}/functions /home/${USERNAME}/.functions
    cp ${DOTFILES_CONFIG_DIR}/zsh_profile /home/${USERNAME}/.zsh_profile
    cp ${DOTFILES_CONFIG_DIR}/zshrc /home/${USERNAME}/.zshrc
}

function setup_nano() {
    echo_info "Setting up nano"

    cp ${DOTFILES_CONFIG_DIR}/nanorc /home/${USERNAME}/.nanorc
}

function setup_git() {
    echo_info "Setting up git"

    cp ${DOTFILES_CONFIG_DIR}/gitignore_global /home/${USERNAME}/.gitignore_global
    cp ${DOTFILES_CONFIG_DIR}/gitconfig /home/${USERNAME}/.gitconfig
}
