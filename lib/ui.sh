#!/usr/bin/env bash
# Terminal output helpers

readonly RESET='\033[0;0m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly DIM='\033[2m'

# All prompts and messages go to the terminal, so they stay visible even when
# a step's output is redirected to the log file.
# Without a terminal (CI, container), prompts fall back to their default answer.
# Messages are written to fd 3 (never "> /dev/stderr", which would truncate a
# log file stderr is redirected to).
if { : > /dev/tty; } 2> /dev/null; then
    exec 3> /dev/tty
    TTY_IN=/dev/tty
else
    exec 3>&2
    TTY_IN=/dev/null
fi

function block() {
    local color=$1
    local text=$2
    local padding
    padding=$(printf '%*s' "$(( ${#text} + 4 ))" '')

    echo -en "\n\033[${color}m\033[1;37m${padding}\033[0m\n" >&3
    echo -en "\033[${color}m\033[1;37m  ${text}  \033[0m\n" >&3
    echo -en "\033[${color}m\033[1;37m${padding}\033[0m\n\n" >&3
}

function block_error() { block "41" "${1}"; }
function block_success() { block "42" "${1}"; }
function block_warning() { block "43" "${1}"; }
function block_info() { block "44" "${1}"; }

function echo_error() { echo -e "${RED}${1}${RESET}" >&3; }
function echo_success() { echo -e "${GREEN}${1}${RESET}" >&3; }
function echo_warning() { echo -e "${YELLOW}${1}${RESET}" >&3; }
function echo_info() { echo -e "${CYAN}${1}${RESET}" >&3; }
function echo_dim() { echo -e "${DIM}${1}${RESET}" >&3; }

# ask_value "message" ["default"] -> prints the answer on stdout
function ask_value() {
    local message=$1
    local default_value=${2:-}
    local value
    local default_value_message=''

    if [[ -n "${default_value}" ]]; then
        default_value_message=" (default: ${YELLOW}${default_value}${CYAN})"
    fi

    echo -en "${CYAN}${message}${default_value_message}: ${RESET}" >&3
    read -r value < "${TTY_IN}" || true

    echo "${value:-${default_value}}"
}

# ask_choice "message" "keys" "default" -> prints the chosen key (lowercase)
# e.g. ask_choice "[r]etry / [s]kip / [a]bort" "rsa" "r"
function ask_choice() {
    local message=$1
    local keys=$2
    local default_key=$3
    local answer

    while true; do
        answer=$(ask_value "${message}" "${default_key}")
        answer=${answer,,}
        answer=${answer:0:1}
        if [[ -n "${answer}" && "${keys}" == *"${answer}"* ]]; then
            echo "${answer}"
            return
        fi
        echo_warning "Choix invalide, réponses possibles : ${keys}"
    done
}
