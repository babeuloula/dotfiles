#!/usr/bin/env bash
# Claude Code desktop notifications, called by the Stop and Notification hooks.
#   notify.sh done     Claude has finished (skipped while background tasks still run)
#   notify.sh waiting  Claude is waiting for you (permission, question...)
# The hook JSON is read on stdin.

kind=${1:-done}
input=$(cat)

field() { jq -r "$1" <<< "${input}" 2> /dev/null; }

session=$(field '.session_id // "default"')
project=$(basename "$(field '.cwd // empty')")
title="Claude Code${project:+ · ${project}}"

case "${kind}" in
    done)
        # A background agent or command is still running: Claude will stop
        # again once it completes, notify only then.
        [[ "$(field '(.background_tasks // []) | length')" == "0" ]] || exit 0
        body="Terminé"
        sound="complete"
        ;;
    waiting)
        body=$(field '.message // empty')
        body=${body:-"Claude attend une réponse"}
        sound="window-question"
        ;;
    *) exit 0 ;;
esac

if [[ "$(uname -s)" == "Darwin" ]]; then
    osascript -e "display notification \"${body//\"/\\\"}\" with title \"${title//\"/\\\"}\"" 2> /dev/null
    exit 0
fi

# One notification per session, replaced instead of stacked, and grouped
# under the "Claude Code" application in GNOME (desktop-entry hint).
state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"
mkdir -p "${state_dir}"
id_file="${state_dir}/${session}"
replace=()
[[ -s "${id_file}" ]] && replace=(--replace-id="$(cat "${id_file}")")

notify-send --print-id "${replace[@]}" \
    --app-name="Claude Code" \
    --icon="$HOME/.claude/icon.png" \
    --hint=string:desktop-entry:claude-code \
    --hint=string:sound-name:"${sound}" \
    "${title}" "${body}" > "${id_file}" 2> /dev/null
