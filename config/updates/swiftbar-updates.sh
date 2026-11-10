#!/bin/bash
# SwiftBar plugin, installed as ~/.swiftbar/updates.6h.sh (the "6h" suffix is
# the refresh interval). Does not run "brew update": the LaunchAgent does.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

out=$(brew outdated --quiet 2> /dev/null)
n=$(printf '%s' "${out}" | grep -c .)

cork=""
if versions=$("$HOME/.local/bin/cork-update" --check 2> /dev/null); [[ $? -eq 10 ]]; then
    cork=" · Cork"
fi

echo "🍺 ${n}${cork}"
echo "---"
[[ -n "${out}" ]] && echo "${out}"
echo "Mettre à jour Homebrew | bash=$(command -v brew) param1=upgrade terminal=true refresh=true"
if [[ -n "${cork}" ]]; then
    echo "---"
    echo "Cork : ${versions/ / → }"
    echo "Recompiler Cork | bash=$HOME/.local/bin/cork-update terminal=true refresh=true"
fi
echo "---"
echo "Rafraîchir | refresh=true"
