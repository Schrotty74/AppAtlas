#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

requested_version="${1:-}"
temporary_index=""

cleanup() {
    if [[ -n "$temporary_index" && -f "$temporary_index" ]]; then
        rm -f "$temporary_index"
    fi
}
trap cleanup EXIT

build_setting() {
    local name="$1"
    xcodebuild \
        -project AppAtlas.xcodeproj \
        -scheme "AppAtlas Beta" \
        -configuration Beta \
        -showBuildSettings 2>/dev/null \
        | awk -F' = ' -v setting="$name" '$1 ~ setting "$" { print $2; exit }'
}

release_version() {
    if [[ -n "$requested_version" ]]; then
        echo "$requested_version"
        return
    fi

    local marketing_version
    marketing_version="$(build_setting MARKETING_VERSION)"
    if [[ -z "$marketing_version" ]]; then
        echo "Abbruch: Beta-Version fehlt und MARKETING_VERSION konnte nicht gelesen werden." >&2
        echo "Aufruf: $0 1.2.0-beta.3" >&2
        exit 1
    fi
    echo "$marketing_version"
}

require_dev_branch() {
    local branch
    branch="$(git branch --show-current)"
    if [[ "$branch" != "dev" ]]; then
        echo "Abbruch: Beta muss vom aktuellen dev-Branch erstellt werden." >&2
        echo "Aktueller Branch: $branch" >&2
        exit 1
    fi
}

ensure_beta_ref() {
    if git show-ref --verify --quiet refs/heads/beta; then
        return
    fi

    if git show-ref --verify --quiet refs/remotes/origin/beta; then
        git update-ref refs/heads/beta refs/remotes/origin/beta
        return
    fi

    git update-ref refs/heads/beta HEAD
}

worktree_tree() {
    temporary_index="$(mktemp /tmp/appatlas-beta-index.XXXXXX)"
    rm -f "$temporary_index"
    GIT_INDEX_FILE="$temporary_index" git read-tree HEAD
    GIT_INDEX_FILE="$temporary_index" git add -A -- .
    GIT_INDEX_FILE="$temporary_index" git write-tree
}

create_beta_commit() {
    local version="$1"
    local tree="$2"
    local parent
    local parent_tree
    local message

    parent="$(git rev-parse refs/heads/beta)"
    parent_tree="$(git rev-parse "$parent^{tree}")"
    if [[ "$tree" == "$parent_tree" ]]; then
        echo "$parent"
        return
    fi

    message="Create beta $version from dev"
    printf '%s\n' "$message" | git commit-tree "$tree" -p "$parent"
}

require_dev_branch
ensure_beta_ref

version="$(release_version)"
dev_commit="$(git rev-parse --short HEAD)"

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Beta" \
    -configuration Beta \
    -destination 'generic/platform=macOS' \
    build

APPATLAS_VERSION="$version" \
    APPATLAS_ALLOW_RELEASE_PACKAGE=YES \
    ./Scripts/build-release-package.sh beta

./Scripts/privacy-check.sh

tree="$(worktree_tree)"
beta_before="$(git rev-parse refs/heads/beta)"
beta_commit="$(create_beta_commit "$version" "$tree")"
git update-ref refs/heads/beta "$beta_commit" "$beta_before"
git push --set-upstream origin refs/heads/beta:refs/heads/beta

echo "Beta wurde aus Dev erstellt."
echo "Version: $version"
echo "ZIP, DMG und SHA256-Dateien wurden erzeugt."
echo "Branch beta wurde zu origin gepusht."
echo "Dev-Commit: $dev_commit"
echo "Beta-Commit: $(git rev-parse --short "$beta_commit")"
echo "Aktueller Branch: $(git branch --show-current)"
