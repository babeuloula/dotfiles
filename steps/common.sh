#!/usr/bin/env bash
# Steps shared by every profile

function setup_zsh() {
    echo_info "Setting up zsh"

    local zsh_path
    zsh_path=$(command -v zsh)
    if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
        grep -qx "${zsh_path}" /etc/shells || echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
        sudo chsh -s "${zsh_path}" "$(id -un)"
    fi

    # --unattended: do not start a new zsh, which would stop the installer
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    fi

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    download https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme \
        "${zsh_custom}/themes/babeuloula.zsh-theme"
    git_clone_or_pull https://github.com/zsh-users/zsh-autosuggestions "${zsh_custom}/plugins/zsh-autosuggestions"

    if is_macos; then
        brew_install --cask font-hack-nerd-font
    fi

    link_config aliases "$HOME/.aliases"
    link_config dockerfunc "$HOME/.dockerfunc"
    link_config functions "$HOME/.functions"
    link_config zsh_profile "$HOME/.zsh_profile"
    link_config zshrc "$HOME/.zshrc"
    if [[ "${DOTFILES_PROFILE}" == "linux-desktop" ]]; then
        link_config scaleway "$HOME/.scaleway"
    fi
}

function setup_git() {
    echo_info "Setting up git"

    link_config gitignore_global "$HOME/.gitignore_global"
    link_config gitconfig "$HOME/.gitconfig"

    if is_macos; then
        link_config git/macos.gitconfig "$HOME/.gitconfig.os"
    else
        link_config git/linux.gitconfig "$HOME/.gitconfig.os"
    fi
}

function setup_nano() {
    echo_info "Setting up nano"

    link_config nanorc "$HOME/.nanorc"
}

function setup_psysh() {
    echo_info "Setting up psysh"

    download https://psysh.org/psysh "$HOME/.psysh/psysh" +x
    download https://psysh.org/manual/fr/php_manual.sqlite "$HOME/.psysh/php_manual.sqlite"

    mkdir -p "$HOME/.psysh/config"
    cp "${DOTFILES_CONFIG_DIR}/psysh_config.php" "$HOME/.psysh/config/config.php"
}

function setup_claude_code() {
    echo_info "Setting up Claude Code"

    if ! command -v claude > /dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    local settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [[ -f "${settings}" ]] || echo '{}' > "${settings}"

    # Desktop notifications: "done" only when nothing runs in the background,
    # "waiting" when Claude needs an answer, grouped under one application
    link_config claude/notify.sh "$HOME/.claude/notify.sh"
    cp "${DOTFILES_CONFIG_DIR}/claude/icon.png" "$HOME/.claude/icon.png"
    if is_linux; then
        mkdir -p "$HOME/.local/share/applications"
        printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Claude Code' \
            "Icon=$HOME/.claude/icon.png" 'Exec=claude' 'NoDisplay=true' \
            > "$HOME/.local/share/applications/claude-code.desktop"
    fi

    # Status line, notifications, no Claude attribution in commits/PRs
    jq '. + {
        statusLine: {type: "command", command: "bash ~/.claude/statusline.sh", refreshInterval: 600},
        attribution: {commit: "", pr: "", sessionUrl: false}
    } | .hooks = ((.hooks // {}) + {
        Stop: [{hooks: [{type: "command", command: "bash ~/.claude/notify.sh done", async: true}]}],
        Notification: [{
            matcher: "permission_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input",
            hooks: [{type: "command", command: "bash ~/.claude/notify.sh waiting", async: true}]
        }]
    })' "${settings}" > "${settings}.tmp"
    mv "${settings}.tmp" "${settings}"
}

# Always run: the gist can change without any change in this repository
function setup_claude_statusline() {
    echo_info "Updating Claude Code status line"

    download https://gist.githubusercontent.com/babeuloula/bd589aee743367340d6b1d09a117f539/raw/statusline.sh \
        "$HOME/.claude/statusline.sh" +x
}
