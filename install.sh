#!/usr/bin/env bash

set -e

# PROMPT COLOURS
readonly RESET='\033[0;0m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'

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

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo -e "${RED}This script is intended for macOS only.${RESET}"
    exit 1
fi

block "44" "Welcome to your dotfiles installer!"

echo -e "${CYAN}Install Xcode Command Line Tools.${RESET}" > /dev/tty
xcode-select --install 2>/dev/null || echo "Xcode Command Line Tools already installed."

echo -e "${CYAN}Install Homebrew.${RESET}" > /dev/tty
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed."
fi

echo -e "${CYAN}Install git.${RESET}" > /dev/tty
brew install git

echo -e "${CYAN}Clone repo for installation.${RESET}" > /dev/tty
git clone -b macos https://github.com/babeuloula/dotfiles.git ~/.dotfiles

cd ~/.dotfiles
./dotfiles.sh
