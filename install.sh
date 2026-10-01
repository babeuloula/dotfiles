#!/usr/bin/env bash
# Bootstrap: curl -fsSL https://raw.githubusercontent.com/babeuloula/dotfiles/main/install.sh | bash
# Must stay compatible with bash 3.2 (default bash on macOS).

set -e

readonly REPO_URL="https://github.com/babeuloula/dotfiles.git"
readonly BRANCH="main"
readonly DOTFILES_DIR="$HOME/.dotfiles"

readonly RESET='\033[0;0m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'

function info() { echo -e "${CYAN}$1${RESET}"; }
function error() { echo -e "${RED}$1${RESET}" >&2; }

function load_brew() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

function bootstrap_macos() {
    info "Install Xcode Command Line Tools."
    if ! xcode-select -p > /dev/null 2>&1; then
        xcode-select --install
        info "Terminez l'installation des Command Line Tools puis appuyez sur Entrée."
        read -r < /dev/tty
    fi

    info "Install Homebrew."
    load_brew
    if ! command -v brew > /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
        load_brew
    fi

    # dotfiles.sh needs bash >= 4, macOS only ships bash 3.2
    info "Install git and bash."
    brew install git bash
}

function bootstrap_linux() {
    info "Install git and curl."
    sudo apt-get update
    sudo apt-get install -y git curl
}

function main() {
    case "$(uname -s)" in
        Darwin) bootstrap_macos ;;
        Linux)
            if ! command -v apt-get > /dev/null; then
                error "Seules les distributions basées sur Debian/Ubuntu sont supportées."
                exit 1
            fi
            bootstrap_linux
            ;;
        *)
            error "OS non supporté : $(uname -s)"
            exit 1
            ;;
    esac

    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        info "Update ${DOTFILES_DIR}."
        git -C "${DOTFILES_DIR}" pull --rebase --autostash
    else
        info "Clone repo into ${DOTFILES_DIR}."
        git clone -b "${BRANCH}" "${REPO_URL}" "${DOTFILES_DIR}"
    fi

    # Use the bash found in PATH (the Homebrew one on macOS)
    # stdin is the curl pipe: give the installer the terminal back for its prompts
    if { : < /dev/tty; } 2> /dev/null; then
        exec bash "${DOTFILES_DIR}/dotfiles.sh" install "$@" < /dev/tty
    fi
    exec bash "${DOTFILES_DIR}/dotfiles.sh" install "$@"
}

main "$@"
