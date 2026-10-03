#!/usr/bin/env bash
# Steps for the macOS profile

function install_brew_packages() {
    echo_info "Install Homebrew packages"

    brew update
    brew upgrade

    echo_info " - Formulas"
    brew_install \
        bat \
        bash \
        bash-completion \
        cheat \
        fd \
        ffmpeg \
        fzf \
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
        terraform \
        tree \
        mnapoli/tap/promptedit

    echo_info " - Casks"
    brew tap TheBoredTeam/boring-notch
    brew_install --cask \
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
        vlc \
        TheBoredTeam/boring-notch/boring-notch

    echo_info " - fzf"
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
}

function install_node() {
    echo_info "Install Node.js via nvm"

    brew_install nvm
    mkdir -p "$HOME/.nvm"

    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    source "$(brew --prefix nvm)/nvm.sh"

    nvm install --lts
    nvm alias default 'lts/*'
}

function install_orbstack() {
    echo_info "Install OrbStack (Docker runtime)"

    brew_install --cask orbstack

    echo_info "Install LazyDocker"
    brew_install jesseduffield/lazydocker/lazydocker
    link_config lazydocker.yml "$HOME/.config/lazydocker/config.yml"
}

function setup_iterm2() {
    echo_info "Setting up iTerm2"
    echo_warning "→ Configure iTerm2 manually via Preferences > Profiles."
    echo_warning "  Tip: Preferences > General > Preferences > Load from custom folder to sync settings."
}

function install_and_setup_mouse_and_keyboard_macos() {
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
    brew_install --cask logi-options+

    echo_warning "→ Keyboard shortcuts (Toggle mic, Spotify, iTerm2, PhpStorm, DataGrip, VSCode)"
    echo_warning "  must be configured manually in:"
    echo_warning "  System Settings > Keyboard > Keyboard Shortcuts"
    echo_warning "  Toggle mic script: $HOME/.local/bin/toggle-mic.sh"
}

function clean_brew() {
    echo_info "Clean Homebrew"

    brew cleanup
}
