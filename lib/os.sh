#!/usr/bin/env bash
# OS and profile detection, sudo session

readonly PROFILES=(linux-desktop linux-server macos)

# detect_os -> linux | macos
function detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) return 1 ;;
    esac
}

# detect_linux_profile -> "desktop <reason>" | "server <reason>" (empty when undecidable)
# Relies on what is installed on the machine, not on the current session,
# so running the installer over SSH on a desktop still detects a desktop.
function detect_linux_profile() {
    local target=""
    local de

    if command -v systemctl > /dev/null; then
        target=$(systemctl get-default 2> /dev/null || true)
    fi

    if [[ "${target}" == "graphical.target" ]]; then
        echo "desktop graphical.target"
        return
    fi

    for de in gnome-shell plasmashell xfce4-session cinnamon-session mate-session lxqt-session; do
        if command -v "${de}" > /dev/null; then
            echo "desktop ${de}"
            return
        fi
    done

    if [[ "${target}" == "multi-user.target" ]]; then
        echo "server multi-user.target"
    fi
}

function is_valid_profile() {
    local profile
    for profile in "${PROFILES[@]}"; do
        [[ "${profile}" == "$1" ]] && return 0
    done
    return 1
}

# resolve_profile [forced_profile] [persist=1] -> sets DOTFILES_PROFILE (and remembers it)
function resolve_profile() {
    local forced=${1:-}
    local persist=${2:-1}
    local profile_file="${DOTFILES_STATE_DIR}/profile"
    local os detection kind reason

    if [[ -n "${forced}" ]]; then
        is_valid_profile "${forced}" || {
            echo_error "Profil inconnu : ${forced} (valeurs possibles : ${PROFILES[*]})"
            return 1
        }
        DOTFILES_PROFILE=${forced}
    elif [[ -f "${profile_file}" ]] && is_valid_profile "$(cat "${profile_file}")"; then
        DOTFILES_PROFILE=$(cat "${profile_file}")
    else
        os=$(detect_os) || {
            echo_error "OS non supporté : $(uname -s)"
            return 1
        }

        if [[ "${os}" == "macos" ]]; then
            DOTFILES_PROFILE="macos"
            echo_info "Profil détecté : macos"
        else
            detection=$(detect_linux_profile)
            if [[ -n "${detection}" ]]; then
                kind=${detection%% *}
                reason=${detection#* }
                DOTFILES_PROFILE="linux-${kind}"
                echo_info "Profil détecté : ${DOTFILES_PROFILE} (${reason})"
            else
                echo_warning "Impossible de détecter s'il s'agit d'un poste de travail ou d'un serveur."
                case "$(ask_choice "[d]esktop ou [s]erveur ?" "ds" "s")" in
                    d) DOTFILES_PROFILE="linux-desktop" ;;
                    s) DOTFILES_PROFILE="linux-server" ;;
                esac
            fi
        fi
    fi

    if [[ "${persist}" == "1" ]]; then
        mkdir -p "${DOTFILES_STATE_DIR}"
        echo "${DOTFILES_PROFILE}" > "${profile_file}"
    fi
    export DOTFILES_PROFILE
}

function is_macos() { [[ "${DOTFILES_PROFILE}" == "macos" ]]; }
function is_linux() { [[ "${DOTFILES_PROFILE}" == linux-* ]]; }
function is_desktop() { [[ "${DOTFILES_PROFILE}" == "linux-desktop" || "${DOTFILES_PROFILE}" == "macos" ]]; }

# Ask for the sudo password once and keep the session alive until we exit,
# so a long step does not stop halfway on a password prompt.
function start_sudo_session() {
    [[ ${EUID} -eq 0 ]] && return 0

    echo_info "Mot de passe sudo requis pour l'installation."
    # shellcheck disable=SC2024
    sudo -v < "${TTY_IN}"

    ( while kill -0 "$$" 2> /dev/null; do sudo -n true; sleep 50; done ) > /dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
}

function stop_sudo_session() {
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "${SUDO_KEEPALIVE_PID}" 2> /dev/null || true
}
