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

    # Google Chrome
    sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    
    # BalenaEtcher
    echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
    sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 379CE192D401AB61
    
    # Signal
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
    cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
    
    # Sublim Text
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo apt-get install apt-transport-https
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

    sudo apt update
    sudo apt install -y \
        ansible \
        bat \
        bash-completion \
        compizconfig-settings-manager \
        dia \
        ffmpeg \
        firefox \
        fonts-powerline \
        git \
        gnome-tweaks \
        gnupg2 \
        google-chrome-stable \
        htop \
        httpie \
        imagemagick \
        jq \
        less \
        libavcodec-extra \
        make \
        meld \
        nano \
        p7zip-full \
        pavucontrol \
        python3-pygments \
        pv \
        rclone \
        signal-desktop \
        snap \
        snapd \
        ssh \
        stacer \
        sublime-text \
        tilix \
        ubuntu-restricted-extras \
        unzip \
        unrar \
        variety \
        zsh \
        --no-install-recommends
}

function install_snap_packages() {
    echo_info "Install SNAP packages"

    echo_info " - GIMP"
    sudo snap install --classic gimp
    
    echo_info " - GitKraken"
    sudo snap install --classic gitkraken
    
    echo_info " - Postman"
    sudo snap install --classic postman
    
    echo_info " - Spotify"
    sudo snap install --classic spotify
    
    echo_info " - Termius"
    sudo snap install --classic termius-app
    
    echo_info " - VLC"
    sudo snap install --classic vlc
    
    echo_info " - Indicator Sensors"
    sudo snap install --classic indicator-sensors

    echo_info " - DataGrip"
    sudo snap install --classic datagrip
    
    echo_info " - Discord"
    sudo snap install --classic discord
    
    echo_info " - PhpStorm"
    sudo snap install --classic phpstorm
        
    echo_info " - Slack"
    sudo snap install --classic slack
    
    echo_info " - Ngrok"
    sudo snap install --classic ngrok
    
    echo_info " - Cheat"
    sudo snap install --classic cheat
}

function install_deb_packages() {
    echo_info "Install DEB packages:"
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

function install_minikube() {
    echo_info "Install Kubectl & Minikube"
    
    sudo apt-get update
    sudo apt-get install -y apt-transport-https conntrack
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    kubectl version --client=true --output=yaml
    
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv ./minikube /usr/local/bin/minikube
    minikube version
    minikube start
    minikube status
    minikube stop
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

function setup_variety() {
    sed -i '/^# Gnome 3, Unity*/a gsettings set org.gnome.desktop.background picture-uri-dark "file://$WP" 2> /dev/null' /home/$USER/.config/variety/scripts/set_wallpaper
}
