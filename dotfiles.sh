#!/usr/bin/env bash

set -e

readonly DOCKER_PATH=$(dirname $(realpath $0))
readonly USERNAME=$(logname)

cd ${DOCKER_PATH};

. ./lib/functions.sh

trap trap_exit EXIT

function main() {
    install_apt_packages

    setup_tilix
    setup_zsh
    setup_git
    setup_nano
    setup_variety
    setup_psysh

    install_docker
    install_terraform

    install_snap_packages
    install_deb_packages

    clean_apt

    block_success "Installation finished! Don't forget to restart your computer."
}

main $0 "$@"
