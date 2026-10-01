#!/usr/bin/env bash
# Step engine: runs the steps of a profile, only those whose definition changed
# since their last successful run, with a retry / skip / abort menu on failure.
#
# A step is a shell function listed in profiles/<profile>. Its fingerprint is the
# hash of its code plus the content of the config files it reads through
# "${DOTFILES_CONFIG_DIR}/<file>" (copied or loaded files). Files only symlinked
# with link_config are not part of it: a git pull already updates them.

STEP_NAMES=()
STEP_ALWAYS=()
RESULT_RAN=()
RESULT_SKIPPED=()
RESULT_FAILED=()
RESULT_UP_TO_DATE=()

function steps_state_dir() {
    echo "${DOTFILES_STATE_DIR}/steps"
}

# load_profile <profile>: fills STEP_NAMES / STEP_ALWAYS
function load_profile() {
    local file="${DOTFILES_DIR}/profiles/$1"
    local line always

    STEP_NAMES=()
    STEP_ALWAYS=()

    while IFS= read -r line || [[ -n "${line}" ]]; do
        line=${line%%#*}
        line=${line//[[:space:]]/}
        [[ -z "${line}" ]] && continue

        always=0
        if [[ "${line}" == always:* ]]; then
            always=1
            line=${line#always:}
        fi

        if ! declare -F "${line}" > /dev/null; then
            echo_error "Étape inconnue dans profiles/$1 : ${line}"
            return 1
        fi

        STEP_NAMES+=("${line}")
        STEP_ALWAYS+=("${always}")
    done < "${file}"
}

function hash_stdin() {
    if command -v sha256sum > /dev/null; then
        sha256sum | cut -d' ' -f1
    else
        shasum -a 256 | cut -d' ' -f1
    fi
}

function step_fingerprint() {
    local step=$1
    local body file

    body=$(declare -f "${step}")
    {
        echo "${body}"
        grep -o 'DOTFILES_CONFIG_DIR}/[A-Za-z0-9._/-]*' <<< "${body}" | sort -u | while read -r file; do
            file="${DOTFILES_CONFIG_DIR}/${file#DOTFILES_CONFIG_DIR\}/}"
            [[ -f "${file}" ]] && cat "${file}"
        done
    } | hash_stdin
}

# step_state <step> -> new | changed | ok
function step_state() {
    local file
    file="$(steps_state_dir)/$1.sha"

    if [[ ! -f "${file}" ]]; then
        echo "new"
    elif [[ "$(cat "${file}")" != "$(step_fingerprint "$1")" ]]; then
        echo "changed"
    else
        echo "ok"
    fi
}

function mark_step_done() {
    mkdir -p "$(steps_state_dir)"
    step_fingerprint "$1" > "$(steps_state_dir)/$1.sha"
}

function has_any_state() {
    compgen -G "$(steps_state_dir)/*.sha" > /dev/null
}

# step_selected <step>: honours --only
function step_selected() {
    local only
    [[ ${#OPT_ONLY[@]} -eq 0 ]] && return 0
    for only in "${OPT_ONLY[@]}"; do
        [[ "${only}" == "$1" ]] && return 0
    done
    return 1
}

# step_needs_run <index>
function step_needs_run() {
    local i=$1
    local step=${STEP_NAMES[$i]}

    step_selected "${step}" || return 1
    [[ "${OPT_FORCE}" == "1" || ${#OPT_ONLY[@]} -gt 0 ]] && return 0
    [[ "${STEP_ALWAYS[$i]}" == "1" ]] && return 0
    [[ "$(step_state "${step}")" != "ok" ]]
}

function print_status() {
    local i step state label

    block_info "Profil ${DOTFILES_PROFILE}"

    for i in "${!STEP_NAMES[@]}"; do
        step=${STEP_NAMES[$i]}
        state=$(step_state "${step}")

        if [[ "${STEP_ALWAYS[$i]}" == "1" ]]; then
            label="${CYAN}↻ toujours exécutée${RESET}"
        else
            case "${state}" in
                ok) label="${GREEN}✔ à jour${RESET}" ;;
                changed) label="${YELLOW}● modifiée${RESET}" ;;
                new) label="${YELLOW}+ jamais exécutée${RESET}" ;;
            esac
        fi

        printf '  %-45s %b\n' "${step}" "${label}" > "${TTY}"
    done
    echo > "${TTY}"
}

# run_step <step>: 0 = done, 1 = skipped, 2 = abort
function run_step() {
    local step=$1
    local output rc

    while true; do
        block_info "${step}"
        output=$(mktemp)

        {
            echo "===== $(date '+%F %T') ${step}"
            # A separate bash process: "set -e" would be ignored in a subshell
            # here, since run_step itself is called from a condition.
            # shellcheck disable=SC2016
            "${BASH}" -c '
                set -Eeo pipefail
                for file in "${DOTFILES_DIR}"/lib/*.sh "${DOTFILES_DIR}"/steps/*.sh; do
                    source "${file}"
                done
                "$1"
            ' _ "${step}" < "${TTY_IN}" 2>&1
        } | tee -a "${LOG_FILE}" "${output}"
        rc=${PIPESTATUS[0]}

        if [[ ${rc} -eq 0 ]]; then
            rm -f "${output}"
            mark_step_done "${step}"
            echo_success "✔ ${step}"
            return 0
        fi

        echo > "${TTY}"
        echo_error "✘ ${step} a échoué (code ${rc}). Dernières lignes :"
        tail -n 20 "${output}" > "${TTY}"
        rm -f "${output}"
        echo_dim "Log complet : ${LOG_FILE}"

        # No terminal to ask: stop instead of retrying forever
        [[ "${TTY_IN}" == "/dev/null" ]] && return 2

        case "$(ask_choice "[r]éessayer / [p]asser / [a]rrêter" "rpa" "r")" in
            r) continue ;;
            p) return 1 ;;
            a) return 2 ;;
        esac
    done
}

function print_summary() {
    echo > "${TTY}"
    [[ ${#RESULT_RAN[@]} -gt 0 ]] && echo_success "Exécutées : ${RESULT_RAN[*]}"
    [[ ${#RESULT_UP_TO_DATE[@]} -gt 0 ]] && echo_dim "Déjà à jour : ${#RESULT_UP_TO_DATE[@]} étape(s)"
    [[ ${#RESULT_SKIPPED[@]} -gt 0 ]] && echo_warning "Passées (retentées au prochain lancement) : ${RESULT_SKIPPED[*]}"
    [[ ${#RESULT_FAILED[@]} -gt 0 ]] && echo_error "En échec : ${RESULT_FAILED[*]}"
    return 0
}

# On a machine installed before this engine existed, nothing is recorded yet.
function first_run_choice() {
    local i

    has_any_state && return 0
    [[ "${OPT_FORCE}" == "1" || ${#OPT_ONLY[@]} -gt 0 ]] && return 0

    echo_warning "Aucune étape n'a encore été enregistrée sur ce poste."
    case "$(ask_choice "[t]out exécuter / [m]arquer tout comme déjà fait / [p]as à pas" "tmp" "p")" in
        t) ;;
        p) OPT_STEP_BY_STEP=1 ;;
        m)
            for i in "${!STEP_NAMES[@]}"; do
                [[ "${STEP_ALWAYS[$i]}" == "1" ]] || mark_step_done "${STEP_NAMES[$i]}"
            done
            echo_success "Toutes les étapes sont marquées comme faites."
            ;;
    esac
}

function run_steps() {
    local i step rc

    first_run_choice

    for i in "${!STEP_NAMES[@]}"; do
        step=${STEP_NAMES[$i]}

        if ! step_needs_run "${i}"; then
            step_selected "${step}" && RESULT_UP_TO_DATE+=("${step}")
            continue
        fi

        if [[ "${OPT_STEP_BY_STEP}" == "1" ]]; then
            case "$(ask_choice "Exécuter ${step} ? [o]ui / [n]on / [q]uitter" "onq" "o")" in
                n) RESULT_SKIPPED+=("${step}"); continue ;;
                q) break ;;
            esac
        fi

        run_step "${step}" && rc=0 || rc=$?
        case ${rc} in
            0) RESULT_RAN+=("${step}") ;;
            1) RESULT_SKIPPED+=("${step}") ;;
            2) RESULT_FAILED+=("${step}"); print_summary; return 1 ;;
        esac
    done

    print_summary
    [[ ${#RESULT_FAILED[@]} -eq 0 ]]
}
