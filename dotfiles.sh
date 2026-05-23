#!/usr/bin/env bash

set -e

readonly DOTFILES_PATH=$(dirname $(realpath $0))
readonly USERNAME=$(id -un)

cd ${DOTFILES_PATH};

. ./lib/functions.sh

trap trap_exit EXIT

function main() {
    install_brew_packages
    install_node
    install_orbstack

    setup_iterm2
    setup_zsh
    setup_git
    setup_nano
    setup_psysh
    setup_claude_code

    install_and_setup_mouse_and_keyboard

    clean_brew

    block_success "Installation finished! Don't forget to restart your computer."
}

main $0 "$@"
