#!/usr/bin/env bash
# Idempotent building blocks for steps: each one can be run again safely.

# link_file <source in repo> <target>
# Creates or fixes a symlink. A real file at the target is kept as <target>.bak.
function link_file() {
    local source=$1
    local target=$2

    mkdir -p "$(dirname "${target}")"

    if [[ -e "${target}" && ! -L "${target}" ]]; then
        echo_warning "  ${target} existe déjà, sauvegardé en ${target}.bak"
        mv "${target}" "${target}.bak"
    fi

    ln -sfn "${source}" "${target}"
}

# link_config <file in config/> <target>
function link_config() {
    link_file "${DOTFILES_CONFIG_DIR}/$1" "$2"
}

# download <url> <destination> [mode]
function download() {
    local url=$1
    local destination=$2
    local mode=${3:-}

    mkdir -p "$(dirname "${destination}")"
    curl -fsSL "${url}" -o "${destination}.tmp"
    mv "${destination}.tmp" "${destination}"
    [[ -n "${mode}" ]] && chmod "${mode}" "${destination}"
    return 0
}

# git_clone_or_pull <repo url> <directory>
function git_clone_or_pull() {
    local url=$1
    local directory=$2

    if [[ -d "${directory}/.git" ]]; then
        git -C "${directory}" pull --ff-only --quiet
    else
        git clone --quiet "${url}" "${directory}"
    fi
}

function apt_install() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

function apt_update() {
    sudo apt-get update
}

# add_apt_repo <name> <key url> <repo line, with SIGNED_BY placeholder>
# The key is stored dearmored in /usr/share/keyrings/<name>.gpg and the source
# list is overwritten (never appended), so running it twice changes nothing.
function add_apt_repo() {
    local name=$1
    local key_url=$2
    local repo_line=$3
    local keyring="/usr/share/keyrings/${name}.gpg"
    local tmp

    tmp=$(mktemp -d)
    curl -fsSL "${key_url}" -o "${tmp}/key"
    gpg --dearmor --yes -o "${tmp}/key.gpg" "${tmp}/key"
    sudo install -m 0644 "${tmp}/key.gpg" "${keyring}"
    rm -rf "${tmp}"

    echo "${repo_line//SIGNED_BY/signed-by=${keyring}}" | sudo tee "/etc/apt/sources.list.d/${name}.list" > /dev/null
}

# snap_install [--classic] <package>...
function snap_install() {
    local classic=""
    local package

    if [[ "${1:-}" == "--classic" ]]; then
        classic="--classic"
        shift
    fi

    for package in "$@"; do
        if snap list "${package}" > /dev/null 2>&1; then
            echo_dim "  ${package} déjà installé"
        else
            echo_info "  - ${package}"
            sudo snap install ${classic} "${package}"
        fi
    done
}

# brew_install [--cask] <package>...  (only installs what is missing)
function brew_install() {
    local kind="--formula"
    local package
    local missing=()

    if [[ "${1:-}" == "--cask" ]]; then
        kind="--cask"
        shift
    fi

    for package in "$@"; do
        brew list "${kind}" "${package##*/}" > /dev/null 2>&1 || missing+=("${package}")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo_dim "  tout est déjà installé"
        return 0
    fi

    brew install "${kind}" "${missing[@]}"
}
