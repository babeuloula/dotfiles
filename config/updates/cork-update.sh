#!/bin/bash
# Builds Cork (https://github.com/buresdv/Cork) from its latest stable tag, with the
# free "Self-Compiled" scheme, and installs it in /Applications.
#   cork-update            build and install when a newer version exists
#   cork-update --force    build and install even when already up to date
#   cork-update --check    print "<installed> <latest>", exit 10 when an update exists
# Runs with macOS' bash 3.2 (LaunchAgent).

set -eo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export MISE_YES=1

readonly REPO_URL="https://github.com/buresdv/Cork.git"
readonly SOURCE_DIR="$HOME/Applications/Cork"
readonly APP="/Applications/Cork.app"
readonly LOG="$HOME/Library/Logs/cork-update.log"

function installed_version() {
    defaults read "${APP}/Contents/Info.plist" CFBundleShortVersionString 2> /dev/null || true
}

# Latest stable tag, without its "v" prefix (the bundle version has none)
function latest_tag() {
    git ls-remote --tags --refs "${REPO_URL}" \
        | sed 's#.*refs/tags/##' \
        | grep -viE 'beta|alpha|rc' \
        | sort -V \
        | tail -1
}

function main() {
    local mode=${1:-} installed tag latest tuist_version archive_dir

    installed=$(installed_version)
    tag=$(latest_tag)
    latest=${tag#v}

    if [[ -z "${tag}" ]]; then
        echo "Impossible de lire les tags de ${REPO_URL}." >&2
        exit 1
    fi

    if [[ "${mode}" == "--check" ]]; then
        echo "${installed:-absent} ${latest}"
        [[ "${installed}" == "${latest}" ]] || exit 10
        exit 0
    fi

    if [[ "${mode}" != "--force" && "${installed}" == "${latest}" ]]; then
        echo "Cork ${installed} est à jour."
        exit 0
    fi

    if [[ ! -d /Applications/Xcode.app ]]; then
        echo "Xcode est requis : installez-le depuis l'App Store puis relancez cork-update." >&2
        exit 1
    fi

    echo "Cork ${installed:-absent} → ${latest}"

    if [[ -d "${SOURCE_DIR}/.git" ]]; then
        git -C "${SOURCE_DIR}" fetch --quiet --tags --force
    else
        mkdir -p "$(dirname "${SOURCE_DIR}")"
        git clone --quiet "${REPO_URL}" "${SOURCE_DIR}"
    fi
    # Generated files (Derived/, *.xcodeproj) are ignored by git: a forced checkout is safe
    git -C "${SOURCE_DIR}" checkout --quiet --force "${tag}"
    cd "${SOURCE_DIR}"

    # The README of each tag pins the Tuist version to use
    tuist_version=$(grep -oE 'tuist@[0-9]+\.[0-9]+\.[0-9]+' README.md | head -1)
    if [[ -z "${tuist_version}" ]]; then
        echo "Version de Tuist introuvable dans le README de ${tag}." >&2
        exit 1
    fi

    : > "${LOG}"
    echo " - ${tuist_version} : install + generate (log : ${LOG})"
    mise exec "${tuist_version}" -- tuist install >> "${LOG}" 2>&1
    # Tuist cannot generate over a previous generation ("Link already exists")
    rm -rf Cork.xcworkspace ./*.xcodeproj Derived
    # --cache-profile none replaced --no-binary-cache in recent Tuist versions
    mise exec "${tuist_version}" -- tuist generate --no-open --cache-profile none >> "${LOG}" 2>&1 \
        || mise exec "${tuist_version}" -- tuist generate --no-open --no-binary-cache >> "${LOG}" 2>&1

    # Same as Team = None + "Sign to Run Locally" in Xcode, without touching the project
    echo " - xcodebuild archive (scheme Self-Compiled), quelques minutes"
    archive_dir=$(mktemp -d)
    trap 'rm -rf "${archive_dir}"' EXIT
    if ! xcodebuild archive \
        -workspace Cork.xcworkspace \
        -scheme Self-Compiled \
        -configuration Release \
        -archivePath "${archive_dir}/Cork.xcarchive" \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        CODE_SIGN_IDENTITY=- \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM= \
        >> "${LOG}" 2>&1; then
        grep -E 'error:' "${LOG}" | sort -u | tail -20 >&2
        echo "Échec de la compilation, log complet : ${LOG}" >&2
        exit 1
    fi

    if pgrep -xq Cork; then
        echo " - Fermeture de Cork"
        osascript -e 'quit app "Cork"' || true
        sleep 2
    fi

    echo " - Installation dans ${APP}"
    rm -rf "${APP}"
    ditto "${archive_dir}/Cork.xcarchive/Products/Applications/Cork.app" "${APP}"

    echo "Cork $(installed_version) installé."
}

main "$@"
