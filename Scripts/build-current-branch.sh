#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

branch="$(git branch --show-current)"

case "$branch" in
    dev)
        scheme="AppAtlas Dev"
        configuration="Dev"
        ;;
    beta)
        echo "Beta wird nicht mehr ueber ein Xcode-Scheme gebaut." >&2
        echo "Bitte ./Scripts/create-beta-from-dev.sh <version> auf dev verwenden." >&2
        exit 1
        ;;
    main)
        echo "Final wird nicht mehr ueber ein Xcode-Scheme gebaut." >&2
        echo "Bitte ./Scripts/publish-beta-as-final.sh verwenden." >&2
        exit 1
        ;;
    *)
        echo "Unbekannter Branch '$branch'." >&2
        echo "Erwartet: dev, beta oder main." >&2
        exit 1
        ;;
esac

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "$scheme" \
    -configuration "$configuration" \
    -destination 'platform=macOS' \
    build
