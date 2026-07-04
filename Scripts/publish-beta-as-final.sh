#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

require_clean_worktree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Abbruch: Es gibt ungespeicherte Git-Änderungen." >&2
        echo "Bitte zuerst committen oder stashen." >&2
        exit 1
    fi
}

ensure_branch_exists() {
    local branch="$1"
    local start_point="$2"
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        git branch "$branch" "$start_point"
    fi
}

require_clean_worktree
ensure_branch_exists beta main
ensure_branch_exists main beta

git switch beta
beta_commit="$(git rev-parse --short HEAD)"

git switch main
git merge --ff-only beta

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Final" \
    -configuration Final \
    -destination 'platform=macOS' \
    build

APPATLAS_ALLOW_RELEASE_PACKAGE=YES ./Scripts/build-release-package.sh final

echo "Final wurde aus Beta veröffentlicht."
echo "ZIP, DMG und SHA256-Dateien wurden erzeugt."
echo "Beta-Commit: $beta_commit"
echo "Aktueller Branch: $(git branch --show-current)"
