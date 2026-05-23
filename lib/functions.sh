#!/usr/bin/env bash

# PROMPT COLOURS
readonly RESET='\033[0;0m'
readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'

readonly DOTFILES_CONFIG_DIR="$HOME/.dotfiles/config"

function ask_value() {
    local message=$1
    local default_value=$2
    local value
    local default_value_message=''

    if [[ ! -z "${default_value}" ]]; then
        default_value_message=" (default: ${YELLOW}${default_value}${CYAN})"
    fi

    echo -e "${CYAN}${message}${default_value_message}: ${RESET}" > /dev/tty
    read value < /dev/tty

    if [[ -z "${value}" ]]; then
        value=${default_value}
    fi

    echo "${value}"
}

function block() {
    local color=$1
    local text=$2
    local title_length=${#text}

    echo -en "\n\033[${color}m\033[1;37m    "
    for x in $(seq 1 ${title_length}); do echo -en " "; done;
    echo -en "\033[0m\n"

    echo -en "\033[${color}m\033[1;37m  ${text}  \033[0m\n"
    echo -en "\033[${color}m\033[1;37m    "
    for x in $(seq 1 ${title_length}); do echo -en " "; done;
    echo -en "\033[0m\n\n"
}

function block_error() {
    block "41" "${1}"
}

function block_success() {
    block "42" "${1}"
}

function block_warning() {
    block "43" "${1}"
}

function block_info() {
    block "44" "${1}"
}

function echo_error() {
    echo -e "${RED}${1} ${RESET}" > /dev/tty
}

function echo_success() {
    echo -e "${GREEN}${1} ${RESET}" > /dev/tty
}

function echo_warning() {
    echo -e "${YELLOW}${1} ${RESET}" > /dev/tty
}

function echo_info() {
    echo -e "${CYAN}${1} ${RESET}" > /dev/tty
}

function echo_replace() {
    echo  -e "$1 \r\c" > /dev/tty
}

function trap_exit() {
    if [[ $? -ne 0 ]]; then
        block_error "An error occurred during dotfiles installation."
    fi
}

function install_brew_packages() {
    echo_info "Install Homebrew packages"

    brew update
    brew upgrade

    echo_info " - Formulas"
    brew install \
        bat \
        bash-completion \
        cheat \
        ffmpeg \
        git \
        gnupg \
        htop \
        httpie \
        imagemagick \
        jq \
        less \
        nano \
        ngrok \
        p7zip \
        pv \
        rclone \
        terraform

    echo_info " - Casks"
    brew install --cask \
        alt-tab \
        appcleaner \
        datagrip \
        discord \
        firefox \
        gimp \
        google-chrome \
        insomnia \
        iterm2 \
        kdrive \
        launchos \
        pearcleaner \
        phpstorm \
        signal \
        slack \
        spotify \
        stats \
        steam \
        termius \
        thaw \
        visual-studio-code \
        vlc

    echo_info " - The Boring Notch"
    brew tap TheBoredTeam/boring-notch
    brew install --cask TheBoredTeam/boring-notch/boring-notch

    echo_info " - PromptEdit"
    brew install mnapoli/tap/promptedit

    echo_info " - Claude-God"
    brew tap lcharvol/tap
    brew install --cask claude-god
}

function install_node() {
    echo_info "Install Node.js via nvm"

    brew install nvm
    mkdir -p "$HOME/.nvm"

    export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"

    nvm install --lts
    nvm use --lts
    nvm alias default node
}

function install_orbstack() {
    echo_info "Install OrbStack (Docker runtime)"

    brew install --cask orbstack

    echo_info "Install LazyDocker"
    brew install jesseduffield/lazydocker/lazydocker
    mkdir -p "$HOME/.config/lazydocker"
    ln -sf "${DOTFILES_CONFIG_DIR}/lazydocker.yml" "$HOME/.config/lazydocker/config.yml"
}

function setup_iterm2() {
    echo_info "Setting up iTerm2"
    echo_warning "→ Configure iTerm2 manually via Preferences > Profiles."
    echo_warning "  Tip: Preferences > General > Preferences > Load from custom folder to sync settings."
}

function setup_zsh() {
    echo_info "Setting up zsh"

    chsh -s /bin/zsh
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    brew install --cask font-hack-nerd-font

    curl -o "$HOME/.oh-my-zsh/custom/themes/babeuloula.zsh-theme" \
        https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme

    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

    local dotfile_links=(
        ".aliases:aliases"
        ".dockerfunc:dockerfunc"
        ".functions:functions"
        ".zsh_profile:zsh_profile"
        ".zshrc:zshrc"
    )

    for entry in "${dotfile_links[@]}"; do
        local target="$HOME/${entry%%:*}"
        local source="${DOTFILES_CONFIG_DIR}/${entry##*:}"
        [[ -f "$target" ]] && rm "$target"
        ln -s "$source" "$target"
    done
}

function setup_nano() {
    echo_info "Setting up nano"

    [[ -f "$HOME/.nanorc" ]] && rm "$HOME/.nanorc"
    ln -s "${DOTFILES_CONFIG_DIR}/nanorc" "$HOME/.nanorc"
}

function setup_git() {
    echo_info "Setting up git"

    [[ -f "$HOME/.gitignore_global" ]] && rm "$HOME/.gitignore_global"
    ln -s "${DOTFILES_CONFIG_DIR}/gitignore_global" "$HOME/.gitignore_global"

    [[ -f "$HOME/.gitconfig" ]] && rm "$HOME/.gitconfig"
    ln -s "${DOTFILES_CONFIG_DIR}/gitconfig" "$HOME/.gitconfig"
}

function setup_psysh() {
    mkdir -p "$HOME/.psysh/config"

    curl -L https://psysh.org/psysh -o "$HOME/.psysh/psysh"
    chmod +x "$HOME/.psysh/psysh"

    curl -L http://psysh.org/manual/fr/php_manual.sqlite -o "$HOME/.psysh/php_manual.sqlite"

    cp "${DOTFILES_CONFIG_DIR}/psysh_config.php" "$HOME/.psysh/config/config.php"
}

function setup_claude_code() {
    curl -fsSL https://claude.ai/install.sh | bash

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
}

function install_and_setup_mouse_and_keyboard() {
    echo_info "Install mouse and keyboard tools"

    mkdir -p "$HOME/.local/bin"

    cat > "$HOME/.local/bin/toggle-mic.sh" << 'EOF'
#!/bin/bash
osascript <<'APPLESCRIPT'
set vol to get volume settings
if input muted of vol then
    set volume without input muted
    display notification "Activé" with title "🎙️ Micro"
else
    set volume with input muted
    display notification "Coupé" with title "🔇 Micro"
end if
APPLESCRIPT
EOF
    chmod +x "$HOME/.local/bin/toggle-mic.sh"

    echo_info " - Logi Options+ (MX Master 3)"
    brew install --cask logi-options+

    echo_warning "→ Keyboard shortcuts (Toggle mic, Spotify, iTerm2, PhpStorm, DataGrip, VSCode)"
    echo_warning "  must be configured manually in:"
    echo_warning "  System Settings > Keyboard > Keyboard Shortcuts"
    echo_warning "  Toggle mic script: $HOME/.local/bin/toggle-mic.sh"
}

function clean_brew() {
    echo_info "Clean Homebrew"

    brew cleanup
}
