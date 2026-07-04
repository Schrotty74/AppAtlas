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
        scheme="AppAtlas Beta"
        configuration="Beta"
        ;;
    main)
        scheme="AppAtlas Final"
        configuration="Final"
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
