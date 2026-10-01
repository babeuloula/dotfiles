#!/usr/bin/env bash

if [[ -z "${BASH_VERSINFO[0]}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "bash >= 4 est requis (version actuelle : ${BASH_VERSION:-inconnue})." >&2
    echo "Sur macOS : lancez install.sh, ou installez bash avec 'brew install bash' puis ouvrez un nouveau terminal." >&2
    exit 1
fi

set -euo pipefail

DOTFILES_DIR=$(cd "$(dirname "$(realpath "$0")")" && pwd)
DOTFILES_CONFIG_DIR="${DOTFILES_DIR}/config"
DOTFILES_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
# shellcheck disable=SC2034 # used by the sourced libs
LOG_FILE="${DOTFILES_STATE_DIR}/install.log"
export DOTFILES_DIR DOTFILES_CONFIG_DIR DOTFILES_STATE_DIR

for lib in "${DOTFILES_DIR}"/lib/*.sh "${DOTFILES_DIR}"/steps/*.sh; do
    # shellcheck source=/dev/null
    source "${lib}"
done

function usage() {
    cat << EOF
Usage: $(basename "$0") <commande> [options]

Commandes :
  install       installe tout ce qui n'est pas encore à jour (reprend après une erreur)
  update        git pull puis applique uniquement ce qui a changé
  status        affiche l'état de chaque étape sans rien exécuter

Options :
  --step-by-step     demande confirmation avant chaque étape
  --only <étape>     n'exécute que cette étape (répétable)
  --force            exécute toutes les étapes, même celles à jour
  --dry-run          identique à status
  --profile <p>      force le profil : ${PROFILES[*]}
  -h, --help         affiche cette aide
EOF
}

COMMAND=""
# shellcheck disable=SC2034 # used by lib/runner.sh
OPT_STEP_BY_STEP=0
# shellcheck disable=SC2034
OPT_FORCE=0
OPT_ONLY=()
OPT_PROFILE=""
ORIGINAL_ARGS=("$@")

while [[ $# -gt 0 ]]; do
    case "$1" in
        install | update | status) COMMAND=$1 ;;
        --step-by-step) OPT_STEP_BY_STEP=1 ;;
        --force) OPT_FORCE=1 ;;
        --only) OPT_ONLY+=("${2:?--only attend un nom d’étape}"); shift ;;
        --profile) OPT_PROFILE=${2:?--profile attend un profil}; shift ;;
        --dry-run) COMMAND="status" ;;
        -h | --help) usage; exit 0 ;;
        *) echo_error "Argument inconnu : $1"; usage; exit 1 ;;
    esac
    shift
done

if [[ -z "${COMMAND}" ]]; then
    usage
    exit 1
fi

function on_exit() {
    local rc=$?
    stop_sudo_session
    if [[ ${rc} -ne 0 ]]; then
        block_error "La commande s'est terminée en erreur. Relancez-la pour reprendre où elle s'est arrêtée."
    fi
}

function update_repository() {
    local before after

    echo_info "Mise à jour du dépôt dotfiles"
    before=$(git -C "${DOTFILES_DIR}" rev-parse HEAD)
    git -C "${DOTFILES_DIR}" pull --rebase --autostash
    after=$(git -C "${DOTFILES_DIR}" rev-parse HEAD)

    if [[ "${before}" != "${after}" ]]; then
        git -C "${DOTFILES_DIR}" --no-pager log --oneline "${before}..${after}" > "${TTY}"
    else
        echo_dim "Déjà à jour."
    fi
}

function main() {
    mkdir -p "${DOTFILES_STATE_DIR}"

    if [[ "${COMMAND}" == "update" ]]; then
        update_repository
        # Run the freshly pulled code, not the one loaded in memory
        local args=()
        local arg
        for arg in "${ORIGINAL_ARGS[@]}"; do
            [[ "${arg}" == "update" ]] && arg="install"
            args+=("${arg}")
        done
        exec "${DOTFILES_DIR}/dotfiles.sh" "${args[@]}"
    fi

    # status only looks: it does not remember a profile forced with --profile
    if [[ "${COMMAND}" == "status" ]]; then
        resolve_profile "${OPT_PROFILE}" 0
    else
        resolve_profile "${OPT_PROFILE}"
    fi
    load_profile "${DOTFILES_PROFILE}"

    if [[ "${COMMAND}" == "status" ]]; then
        print_status
        return 0
    fi

    trap on_exit EXIT
    start_sudo_session

    if run_steps; then
        block_success "Terminé ! (profil ${DOTFILES_PROFILE})"
    else
        return 1
    fi
}

main
