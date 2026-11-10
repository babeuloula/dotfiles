#!/usr/bin/env bash
# Steps for the macOS profile

function install_brew_packages() {
    echo_info "Install Homebrew packages"

    brew update
    brew upgrade

    echo_info " - Formulas"
    brew tap hashicorp/tap
    brew_install \
        bat \
        bash \
        bash-completion \
        cheat \
        fd \
        ffmpeg \
        fzf \
        gh \
        git \
        glab \
        gnupg \
        htop \
        httpie \
        imagemagick \
        jq \
        less \
        nano \
        p7zip \
        pv \
        rclone \
        tree \
        hashicorp/tap/terraform

    echo_info " - Casks"
    brew tap TheBoredTeam/boring-notch
    brew_install --cask \
        alt-tab \
        appcleaner \
        datagrip \
        discord \
        firefox \
        google-chrome \
        insomnia \
        iterm2 \
        kdrive \
        launchos \
        ngrok \
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
        mnapoli/tap/promptedit \
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

function install_android_studio() {
    echo_info "Install Android Studio"

    brew_install --cask android-studio android-commandlinetools

    echo_info " - Android SDK (~/Library/Android/sdk)"
    # Same SDK location as Android Studio's setup wizard, so both share it.
    # The Android CLI replaces the deprecated sdkmanager and accepts the licenses itself.
    local sdk_root="$HOME/Library/Android/sdk"
    local platform

    mkdir -p "${sdk_root}"

    platform=$(android --no-metrics --sdk="${sdk_root}" sdk list --all 'platforms/*' \
        | grep -oE 'platforms/android-[0-9]+ ' \
        | tr -d ' ' \
        | sort -t- -k2 -n \
        | tail -1)

    android --no-metrics --sdk="${sdk_root}" sdk install \
        cmdline-tools/latest \
        platform-tools \
        emulator \
        "${platform}" < /dev/null

    echo_warning "→ Open Android Studio once to finish its setup wizard (keep the SDK at ${sdk_root})."
}

function install_cork() {
    echo_info "Install Cork (self-compiled)"

    # Xcode only comes from the App Store: retry this step once it is installed
    if [[ ! -d /Applications/Xcode.app ]]; then
        echo_error "Xcode est requis pour compiler Cork : installez-le depuis l'App Store,"
        echo_error "puis choisissez [r]éessayer (ou [p]asser et relancez l'installation plus tard)."
        return 1
    fi

    echo_info " - Xcode: active toolchain, license, first launch components"
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch

    # Tuist runs through "mise exec", in the version pinned by Cork's README
    brew_install mise

    link_config updates/cork-update.sh "$HOME/.local/bin/cork-update"

    # Source in ~/Applications/Cork, app in /Applications/Cork.app
    "$HOME/.local/bin/cork-update"
}

# Checks every 6 hours for Homebrew and Cork updates (LaunchAgent) and sends
# a macOS notification
function setup_update_checks() {
    echo_info "Set up Homebrew and Cork update checks"

    link_config updates/cork-update.sh "$HOME/.local/bin/cork-update"
    link_config updates/brew-check.sh "$HOME/.local/bin/brew-check"

    # macOS takes a notification's icon from the app that sends it: a copy of
    # terminal-notifier with its own bundle id, name and icon shows as "Homebrew"
    echo_info " - Notifier Homebrew.app"
    brew_install terminal-notifier
    local app="$HOME/Library/Application Support/brew-notifier/Homebrew.app"
    local info="${app}/Contents/Info.plist"
    local iconset
    rm -rf "${app}"
    mkdir -p "$(dirname "${app}")"
    ditto "$(brew --prefix terminal-notifier)/terminal-notifier.app" "${app}"

    iconset="$(mktemp -d)/Homebrew.iconset"
    mkdir -p "${iconset}"
    local size
    for size in 16 32 128 256 512; do
        sips -z "${size}" "${size}" "${DOTFILES_CONFIG_DIR}/updates/homebrew-icon.png" \
            --out "${iconset}/icon_${size}x${size}.png" > /dev/null
        sips -z "$((size * 2))" "$((size * 2))" "${DOTFILES_CONFIG_DIR}/updates/homebrew-icon.png" \
            --out "${iconset}/icon_${size}x${size}@2x.png" > /dev/null
    done
    rm -f "${app}/Contents/Resources/"*.icns
    iconutil -c icns "${iconset}" -o "${app}/Contents/Resources/Homebrew.icns"
    rm -rf "$(dirname "${iconset}")"

    /usr/libexec/PlistBuddy \
        -c 'Set :CFBundleIdentifier local.brew-notifier' \
        -c 'Set :CFBundleName Homebrew' \
        -c 'Set :CFBundleIconFile Homebrew' \
        -c 'Add :CFBundleDisplayName string Homebrew' \
        "${info}"
    codesign --force --deep --sign - "${app}"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${app}"

    # The first notification asks for permission: do it now rather than from the LaunchAgent
    echo_warning "→ Allow notifications from « Homebrew » if macOS asks."
    "${app}/Contents/MacOS/terminal-notifier" -title "Mises à jour" -group brew-check \
        -message "Les notifications de mises à jour sont actives." || true

    echo_info " - LaunchAgent local.brew-check"
    local label="local.brew-check"
    local plist="$HOME/Library/LaunchAgents/${label}.plist"
    mkdir -p "$(dirname "${plist}")"
    cat > "${plist}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>${label}</string>
    <key>ProgramArguments</key><array><string>$HOME/.local/bin/brew-check</string></array>
    <key>StartInterval</key><integer>21600</integer>
    <key>RunAtLoad</key><true/>
    <key>StandardErrorPath</key><string>$HOME/Library/Logs/brew-check.err</string>
</dict>
</plist>
EOF
    # Reload so a changed plist is taken into account
    launchctl bootout "gui/$(id -u)/${label}" 2> /dev/null || true
    launchctl bootstrap "gui/$(id -u)" "${plist}"
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
