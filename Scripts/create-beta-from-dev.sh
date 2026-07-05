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
        -target AppAtlas \
        -configuration Beta \
        -derivedDataPath "$root_directory/.build/xcode-beta-derived-data" \
        -clonedSourcePackagesDirPath "$root_directory/.build/xcode-beta-source-packages" \
        -packageCachePath "$root_directory/.build/xcode-beta-package-cache" \
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
    local changed_paths

    changed_paths=()
    while IFS= read -r path; do
        changed_paths+=("$path")
    done < <(
        {
            git diff --name-only HEAD --
            git diff --cached --name-only
            git ls-files --others --exclude-standard
        } | sort -u
    )
    if (( ${#changed_paths[@]} > 0 )); then
        git add -A -- "${changed_paths[@]}"
    fi

    git write-tree
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

backup_directory_for_version() {
    local version="$1"
    case "$version" in
        *local*|*test*)
            echo "$root_directory/Backup/local-test/$version"
            ;;
        *)
            echo "$root_directory/Backup/releases/beta/$version"
            ;;
    esac
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

reset_beta_container() {
    local container_directory="$HOME/Library/Containers/at.schrotty.appatlas.beta"
    rm -rf "$container_directory"
}

last_beta_tag() {
    local tag

    tag="$(git describe --tags --match 'v*-beta*' --abbrev=0 HEAD 2>/dev/null || true)"
    if [[ -z "$tag" ]]; then
        echo "Abbruch: kein letzter Beta-Tag gefunden." >&2
        exit 1
    fi

    echo "$tag"
}

categorized_release_changes() {
    local previous_beta_tag="$1"
    local changes

    changes="$(
        git log --reverse --no-merges --format='%b%x1e' "$previous_beta_tag"..HEAD \
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
        echo "Abbruch: keine kategorisierbaren Release-Note-Einträge seit $previous_beta_tag gefunden." >&2
        exit 1
    fi

    echo "$changes"
}

write_release_notes() {
    local notes_file="$1"
    local previous_beta_tag="$2"
    local changes

    changes="$(categorized_release_changes "$previous_beta_tag")"

    cat > "$notes_file" <<EOF
This beta contains the latest AppAtlas fixes and improvements since $previous_beta_tag.

$changes
## Privacy

AppAtlas starts without a personal catalog. Catalogs, local paths, license
values, user-specific icons and backup files are not included in the source
code or release package.

Local catalogs, scan data, icons and caches remain in the local Application
Support folder for the active build variant. License values remain in the
macOS Keychain and are exported only after explicit user action.
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
previous_beta_tag="$(last_beta_tag)"
artifact_base="$(artifact_base_name "$version")"
backup_directory="$(backup_directory_for_version "$version")"
zip_file="$backup_directory/$artifact_base.zip"
dmg_file="$backup_directory/$artifact_base.dmg"
zip_checksum_file="$zip_file.sha256"
dmg_checksum_file="$dmg_file.sha256"
release_notes_file="$backup_directory/AppAtlas-Beta-$version-release-notes.md"

reset_beta_container

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
    "$previous_beta_tag"
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
echo "Ausgabeordner: $backup_directory"
echo "Release Notes: $release_notes_file"
echo "Branch beta wurde zu origin gepusht."
echo "GitHub Release wurde erstellt."
echo "Dev-Commit: $dev_commit"
echo "Beta-Commit: $(git rev-parse --short "$beta_commit")"
echo "Aktueller Branch: $(git branch --show-current)"
