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

artifact_base_name() {
    local version="$1"
    if [[ "$version" == *beta* ]]; then
        echo "AppAtlas-$version-macos"
    else
        echo "AppAtlas-Beta-$version-macos"
    fi
}

require_release_artifacts() {
    local artifact
    for artifact in "$@"; do
        if [[ ! -f "$artifact" ]]; then
            echo "Abbruch: Release-Artefakt fehlt: $artifact" >&2
            exit 1
        fi
    done
}

require_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "Abbruch: GitHub CLI 'gh' wurde nicht gefunden." >&2
        exit 1
    fi
}

release_change_list() {
    local previous_beta="$1"
    local language="$2"
    local note_prefix
    local notes
    local subjects

    case "$language" in
        de)
            note_prefix="Release-Note-DE:"
            ;;
        en)
            note_prefix="Release-Note-EN:"
            ;;
        *)
            echo "Abbruch: unbekannte Release-Notes-Sprache: $language" >&2
            exit 1
            ;;
    esac

    notes="$(
        git log --reverse --no-merges --format='%B%x1e' "$previous_beta"..HEAD \
            | awk -v prefix="$note_prefix" '
                index($0, prefix) == 1 {
                    note = substr($0, length(prefix) + 1)
                    sub(/^[[:space:]]+/, "", note)
                    if (note != "") {
                        print "- " note
                    }
                }
            ' || true
    )"

    if [[ -n "$notes" ]]; then
        echo "$notes"
        return
    fi

    subjects="$(git log --reverse --no-merges --pretty=format:'- %s' "$previous_beta"..HEAD || true)"
    if [[ -n "$subjects" ]]; then
        echo "$subjects"
        return
    fi

    case "$language" in
        de)
            echo "- Diese Beta enthält die aktuellen Änderungen aus dem Dev-Stand."
            ;;
        en)
            echo "- This beta contains the current changes from the dev state."
            ;;
    esac
}

write_release_notes() {
    local notes_file="$1"
    local version="$2"
    local previous_beta="$3"
    local changes_de
    local changes_en

    changes_de="$(release_change_list "$previous_beta" de)"
    changes_en="$(release_change_list "$previous_beta" en)"

    cat > "$notes_file" <<EOF
# AppAtlas $version

## Deutsch

Diese Beta enthält die aktuellen Änderungen aus dem Dev-Stand.

### Änderungen

$changes_de

## English

This beta contains the current changes from the dev state.

### Changes

$changes_en
EOF
}

create_github_release() {
    local version="$1"
    local target_commit="$2"
    local notes_file="$3"
    local zip_file="$4"
    local dmg_file="$5"
    local zip_checksum_file="$6"
    local dmg_checksum_file="$7"
    local release_tag

    release_tag="v$version"
    GH_PROMPT_DISABLED=1 gh release create "$release_tag" \
        "$zip_file" \
        "$dmg_file" \
        "$zip_checksum_file" \
        "$dmg_checksum_file" \
        --target "$target_commit" \
        --title "AppAtlas Beta $version" \
        --notes-file "$notes_file" \
        --prerelease
}

require_dev_branch
ensure_beta_ref
require_gh

version="$(release_version)"
dev_commit="$(git rev-parse --short HEAD)"
artifact_base="$(artifact_base_name "$version")"
backup_directory="$root_directory/Backup"
zip_file="$backup_directory/$artifact_base.zip"
dmg_file="$backup_directory/$artifact_base.dmg"
zip_checksum_file="$zip_file.sha256"
dmg_checksum_file="$dmg_file.sha256"
release_notes_file="$backup_directory/AppAtlas-Beta-$version-release-notes.md"

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Beta" \
    -configuration Beta \
    -destination 'generic/platform=macOS' \
    build

APPATLAS_VERSION="$version" \
    APPATLAS_ALLOW_RELEASE_PACKAGE=YES \
    ./Scripts/build-release-package.sh beta

require_release_artifacts \
    "$zip_file" \
    "$dmg_file" \
    "$zip_checksum_file" \
    "$dmg_checksum_file"

./Scripts/privacy-check.sh

tree="$(worktree_tree)"
beta_before="$(git rev-parse refs/heads/beta)"
beta_commit="$(create_beta_commit "$version" "$tree")"
git update-ref refs/heads/beta "$beta_commit" "$beta_before"
git push --set-upstream origin refs/heads/beta:refs/heads/beta

write_release_notes \
    "$release_notes_file" \
    "$version" \
    "$beta_before"
create_github_release \
    "$version" \
    "$beta_commit" \
    "$release_notes_file" \
    "$zip_file" \
    "$dmg_file" \
    "$zip_checksum_file" \
    "$dmg_checksum_file"

echo "Beta wurde aus Dev erstellt."
echo "Version: $version"
echo "ZIP, DMG und SHA256-Dateien wurden erzeugt."
echo "Release Notes: $release_notes_file"
echo "Branch beta wurde zu origin gepusht."
echo "GitHub Release wurde erstellt."
echo "Dev-Commit: $dev_commit"
echo "Beta-Commit: $(git rev-parse --short "$beta_commit")"
echo "Aktueller Branch: $(git branch --show-current)"
