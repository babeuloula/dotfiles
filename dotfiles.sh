#!/usr/bin/env bash

set -e

readonly DOCKER_PATH=$(dirname $(realpath $0))

cd ${DOCKER_PATH};

. ./lib/functions.sh

trap trap_exit EXIT

function main() {
    check_is_sudo

    install_apt_packages
    install_snap_packages

    install_docker

    clean_apt

    setup_tilix
    setup_zsh
    setup_git
}

main $0 "$@"
