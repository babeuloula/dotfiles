#!/usr/bin/env bash

set -e

readonly DOCKER_PATH=$(dirname $(realpath $0))
readonly USERNAME=$(logname)

cd ${DOCKER_PATH};

. ./lib/functions.sh

trap trap_exit EXIT

function main() {
    install_apt_packages
    install_snap_packages
    install_deb_packages

    install_docker

    clean_apt

    setup_tilix
    setup_zsh
    setup_git
    setup_nano

    block_success "Installation finished!"
}

main $0 "$@"
