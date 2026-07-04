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
ensure_branch_exists dev main
ensure_branch_exists beta dev

git switch dev
dev_commit="$(git rev-parse --short HEAD)"

git switch beta
git merge --ff-only dev

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Beta" \
    -configuration Beta \
    -destination 'platform=macOS' \
    build

echo "Beta wurde aus Dev erstellt."
echo "Dev-Commit: $dev_commit"
echo "Aktueller Branch: $(git branch --show-current)"
