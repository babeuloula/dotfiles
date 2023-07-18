#!/usr/bin/env bash

set -e

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

block "44" "Welcome to your dotfiles installer!"

echo -e "${CYAN}Install minimum requirements before install.${RESET}" > /dev/tty

sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    curl \
    git

echo -e "${CYAN}Clone repo for installation.${RESET}" > /dev/tty
git clone https://github.com/babeuloula/dotfiles.git ~/.dotfiles

cd ~/.dotfiles
git checkout server
./dotfiles.sh
