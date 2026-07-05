#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

requested_version="${1:-}"

build_setting() {
    local name="$1"
    xcodebuild \
        -project AppAtlas.xcodeproj \
        -scheme "AppAtlas Final" \
        -configuration Final \
        -derivedDataPath "$root_directory/.build/xcode-final-derived-data" \
        -clonedSourcePackagesDirPath "$root_directory/.build/xcode-final-source-packages" \
        -packageCachePath "$root_directory/.build/xcode-final-package-cache" \
        -disablePackageRepositoryCache \
        -skipPackageUpdates \
        -skipPackagePluginValidation \
        -skipMacroValidation \
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
        echo "Abbruch: Final-Version fehlt und MARKETING_VERSION konnte nicht gelesen werden." >&2
        echo "Aufruf: $0 1.2.0" >&2
        exit 1
    fi
    echo "$marketing_version"
}

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

reset_final_container() {
    local container_directory="$HOME/Library/Containers/at.schrotty.appatlas"
    rm -rf "$container_directory"
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

last_final_tag() {
    local tag

    tag="$(git describe --tags --match 'v*' --exclude '*beta*' --abbrev=0 HEAD 2>/dev/null || true)"
    if [[ -z "$tag" ]]; then
        echo "Abbruch: kein letzter Final-Tag gefunden." >&2
        exit 1
    fi

    echo "$tag"
}

categorized_release_changes() {
    local previous_final_tag="$1"
    local changes

    changes="$(
        git log --reverse --no-merges --format='%b%x1e' "$previous_final_tag"..HEAD \
            | awk '
                function trim(value) {
                    sub(/^[[:space:]]+/, "", value)
                    sub(/[[:space:]]+$/, "", value)
                    return value
                }

                function bullet(value) {
                    value = trim(value)
                    sub(/^[*-][[:space:]]+/, "", value)
                    return "- " value
                }

                function add(section, value) {
                    value = bullet(value)
                    if (value == "- ") {
                        return
                    }
                    if (section == "fixed") {
                        fixed[++fixed_count] = value
                    } else if (section == "improved") {
                        improved[++improved_count] = value
                    } else if (section == "new") {
                        new_items[++new_count] = value
                    }
                }

                {
                    line = trim($0)
                    if (line == "" || line == "\036") {
                        next
                    }

                    lower = tolower(line)
                    if (lower ~ /(fix|bug|hang|crash|error)/) {
                        add("fixed", line)
                    } else if (lower ~ /(improve|faster|performance|speed)/) {
                        add("improved", line)
                    } else if (lower ~ /(add|new|support)/) {
                        add("new", line)
                    }
                }

                END {
                    if (new_count > 0) {
                        print "## New"
                        print ""
                        for (i = 1; i <= new_count; i++) {
                            print new_items[i]
                        }
                        print ""
                    }
                    if (fixed_count > 0) {
                        print "## Fixed"
                        print ""
                        for (i = 1; i <= fixed_count; i++) {
                            print fixed[i]
                        }
                        print ""
                    }
                    if (improved_count > 0) {
                        print "## Improved"
                        print ""
                        for (i = 1; i <= improved_count; i++) {
                            print improved[i]
                        }
                        print ""
                    }
                }
            ' || true
    )"

    if [[ -z "$changes" ]]; then
        echo "Abbruch: keine kategorisierbaren Release-Note-Einträge seit $previous_final_tag gefunden." >&2
        exit 1
    fi

    echo "$changes"
}

write_release_notes() {
    local notes_file="$1"
    local previous_final_tag="$2"
    local changes

    changes="$(categorized_release_changes "$previous_final_tag")"

    cat > "$notes_file" <<EOF
This stable release contains the latest AppAtlas changes since $previous_final_tag.

$changes
## Privacy

AppAtlas starts without a personal catalog. Catalogs, local paths, license
values, user-specific icons and backup files are not included in the source
code or release package.

Local catalogs, scan data, icons and caches remain in the local Application
Support folder. License values remain in the macOS Keychain and are exported
only after explicit user action.
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
        --title "AppAtlas $version" \
        --notes-file "$notes_file"
}

require_clean_worktree
require_gh
ensure_branch_exists beta main
ensure_branch_exists main beta

version="$(release_version)"
previous_final_tag="$(last_final_tag)"
backup_directory="$root_directory/Backup"
artifact_base="AppAtlas-$version-macos"
zip_file="$backup_directory/$artifact_base.zip"
dmg_file="$backup_directory/$artifact_base.dmg"
zip_checksum_file="$zip_file.sha256"
dmg_checksum_file="$dmg_file.sha256"
release_notes_file="$backup_directory/AppAtlas-$version-release-notes.md"

git switch beta
beta_commit="$(git rev-parse --short HEAD)"

git switch main
git merge --ff-only beta

reset_final_container

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Final" \
    -configuration Final \
    -destination 'platform=macOS' \
    build

APPATLAS_VERSION="$version" \
    APPATLAS_ALLOW_RELEASE_PACKAGE=YES \
    ./Scripts/build-release-package.sh final

require_release_artifacts \
    "$zip_file" \
    "$dmg_file" \
    "$zip_checksum_file" \
    "$dmg_checksum_file"

APPATLAS_ALLOW_PUSH=YES git push --set-upstream origin main

write_release_notes "$release_notes_file" "$previous_final_tag"
create_github_release \
    "$version" \
    "$(git rev-parse HEAD)" \
    "$release_notes_file" \
    "$zip_file" \
    "$dmg_file" \
    "$zip_checksum_file" \
    "$dmg_checksum_file"

echo "Final wurde aus Beta veröffentlicht."
echo "ZIP, DMG und SHA256-Dateien wurden erzeugt."
echo "GitHub Release wurde erstellt."
echo "Beta-Commit: $beta_commit"
echo "Aktueller Branch: $(git branch --show-current)"
