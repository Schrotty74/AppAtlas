#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

ensure_branch_exists() {
    local branch="$1"
    local start_point="$2"
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        git branch "$branch" "$start_point"
    fi
}

has_local_dev_changes() {
    ! git diff --quiet ||
        ! git diff --cached --quiet ||
        [[ -n "$(git ls-files --others --exclude-standard)" ]]
}

ensure_branch_exists dev main
ensure_branch_exists beta dev

git switch dev
dev_commit="$(git rev-parse --short HEAD)"
stash_created="NO"
stash_name="stash@{0}"

restore_local_dev_state() {
    if [[ "$stash_created" == "YES" ]]; then
        git switch dev >/dev/null
        git stash apply --index "$stash_name" >/dev/null
        git stash drop "$stash_name" >/dev/null
        stash_created="NO"
    else
        git switch dev >/dev/null
    fi
}

restore_on_error() {
    local exit_code="$?"
    if [[ "$stash_created" == "YES" ]]; then
        echo "Fehler: Beta-Erstellung wurde abgebrochen. Lokaler Dev-Stand wird wiederhergestellt." >&2
        git switch dev >/dev/null 2>&1 || true
        git stash apply --index "$stash_name" >/dev/null 2>&1 || {
            echo "Der lokale Dev-Stand liegt noch im Git-Stash: $stash_name" >&2
            exit "$exit_code"
        }
        git stash drop "$stash_name" >/dev/null 2>&1 || true
    fi
    exit "$exit_code"
}

if has_local_dev_changes; then
    git stash push --include-untracked -m "AppAtlas local dev snapshot for beta" >/dev/null
    stash_created="YES"
fi

trap restore_on_error ERR

git switch beta
beta_before="$(git rev-parse HEAD)"
git merge --ff-only dev

if [[ "$stash_created" == "YES" ]]; then
    git stash apply --index "$stash_name" >/dev/null
    git add -A
    ./Scripts/privacy-check.sh
    git commit -m "Create beta from local dev snapshot"
elif [[ "$beta_before" == "$(git rev-parse HEAD)" ]]; then
    echo "Beta ist bereits auf dem aktuellen Dev-Stand."
fi

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Beta" \
    -configuration Beta \
    -destination 'generic/platform=macOS' \
    build

APPATLAS_ALLOW_RELEASE_PACKAGE=YES ./Scripts/build-release-package.sh beta

git push origin beta

restore_local_dev_state
trap - ERR

echo "Beta wurde aus Dev erstellt."
echo "ZIP, DMG und SHA256-Dateien wurden erzeugt."
echo "Branch beta wurde zu origin gepusht."
echo "Dev-Commit: $dev_commit"
echo "Lokaler Dev-Stand wurde wiederhergestellt."
echo "Aktueller Branch: $(git branch --show-current)"
