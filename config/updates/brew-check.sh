#!/bin/bash
# Run every 6 hours by the local.brew-check LaunchAgent: refreshes Homebrew's
# metadata and sends a macOS notification when Homebrew or Cork can be updated.
# Clicking the notification opens Cork.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Copy of terminal-notifier with the Homebrew icon (see setup_update_checks)
readonly NOTIFIER="$HOME/Library/Application Support/brew-notifier/Homebrew.app/Contents/MacOS/terminal-notifier"

msg=""

brew update --quiet > /dev/null 2>&1
n=$(brew outdated --quiet 2> /dev/null | grep -c .)
[[ "${n}" -gt 0 ]] && msg="${n} paquet(s) Homebrew à mettre à jour"

if versions=$("$HOME/.local/bin/cork-update" --check 2> /dev/null); [[ $? -eq 10 ]]; then
    msg="${msg:+${msg} · }Cork ${versions/ / → } : lancez cork-update"
fi

[[ -z "${msg}" ]] && exit 0

if [[ -x "${NOTIFIER}" ]]; then
    open_cork=()
    [[ -d /Applications/Cork.app ]] && open_cork=(-open "file:///Applications/Cork.app")
    "${NOTIFIER}" -title "Mises à jour" -message "${msg}" -group brew-check "${open_cork[@]}"
else
    osascript -e "display notification \"${msg}\" with title \"Mises à jour\""
fi
exit 0
