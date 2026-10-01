#!/usr/bin/env bash
# Steps for the Linux desktop profile

function setup_tilix() {
    echo_info "Setting up Tilix"

    dconf load /com/gexperts/Tilix/ < "${DOTFILES_CONFIG_DIR}/tilix.conf"
}

function setup_variety() {
    echo_info "Setting up Variety"

    local script="$HOME/.config/variety/scripts/set_wallpaper"
    # shellcheck disable=SC2016
    local line='gsettings set org.gnome.desktop.background picture-uri-dark "file://$WP" 2> /dev/null'

    # The script only exists once Variety has been started
    if [[ ! -f "${script}" ]]; then
        echo_warning "  Lancez Variety une première fois puis relancez : ./dotfiles.sh install --only setup_variety"
        return 0
    fi

    grep -qF "${line}" "${script}" || sed -i "/^# Gnome 3, Unity*/a ${line}" "${script}"
}

function install_snap_packages() {
    echo_info "Install SNAP packages"

    snap_install --classic \
        cheat \
        code \
        datagrip \
        discord \
        gimp \
        gitkraken \
        indicator-sensors \
        ngrok \
        phpstorm \
        postman \
        slack \
        spotify \
        termius-app \
        vlc
}

# set_keybinding <index> <name> <command> <binding>
function set_keybinding() {
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$1/"
    local schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}"

    gsettings set "${schema}" name "$2"
    gsettings set "${schema}" command "$3"
    gsettings set "${schema}" binding "$4"
}

function install_and_setup_mouse_and_keyboard() {
    echo_info "Install mouse and keyboard"

    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/toggle-mic.sh" << 'EOF'
#!/bin/bash
SOURCE=$(pactl get-default-source)

# Toggle direct, sans lire l'état
pactl set-source-mute "$SOURCE" toggle

# Lire l'état APRÈS le toggle pour la notification
MUTED=$(pactl get-source-mute "$SOURCE")

if echo "$MUTED" | grep -iqE "oui|yes"; then
    notify-send "🔇 Micro" "Coupé" --expire-time=1500
else
    notify-send "🎙️ Micro" "Activé" --expire-time=1500
fi
EOF
    chmod +x "$HOME/.local/bin/toggle-mic.sh"

    local base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
        "['${base}/custom0/', '${base}/custom1/', '${base}/custom2/', '${base}/custom3/', '${base}/custom4/', '${base}/custom5/']"

    set_keybinding 0 'Toggle mic' "$HOME/.local/bin/toggle-mic.sh" '<Shift><Control><Alt>F1' # F13
    set_keybinding 1 'Spotify' 'spotify' '<Shift><Control><Alt>F2'                         # F14
    set_keybinding 2 'Tilix' 'tilix' '<Super>r'
    set_keybinding 3 'PHPStorm' 'phpstorm' '<Shift><Control><Alt>F4'                       # F16
    set_keybinding 4 'DataGrip' 'datagrip' '<Shift><Control><Alt>F5'                       # F17
    set_keybinding 5 'VSCode' 'code' '<Shift><Control><Alt>F6'                             # F18

    sudo add-apt-repository -y ppa:solaar-unifying/stable
    apt_update
    apt_install logiops solaar

    sudo cp "${DOTFILES_CONFIG_DIR}/logid.cfg" /etc/logid.cfg
    sudo cp "${DOTFILES_CONFIG_DIR}/restart-logid.service" /etc/systemd/system/restart-logid.service

    sudo systemctl daemon-reload
    sudo systemctl enable --now logid
    sudo systemctl enable restart-logid.service
    sudo systemctl restart restart-logid.service
}
