#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

xcodebuild \
    -project AppAtlas.xcodeproj \
    -scheme "AppAtlas Beta" \
    -configuration Beta \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$root_directory/.build/xcode-beta-derived-data" \
    -clonedSourcePackagesDirPath "$root_directory/.build/xcode-beta-source-packages" \
    -packageCachePath "$root_directory/.build/xcode-beta-package-cache" \
    -disablePackageRepositoryCache \
    -skipPackageUpdates \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    build
