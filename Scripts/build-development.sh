#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
scratch_directory="$root_directory/.build/development"
output_directory="$root_directory/dist/AppAtlas-Development"
app_bundle="$output_directory/AppAtlas.app"
version="1.0.0-development"
build_number="1"

swift build \
    --package-path "$root_directory" \
    --scratch-path "$scratch_directory" \
    --configuration release

resource_accessor="$(
    find "$scratch_directory" \
        -path '*/AppAtlas.build/DerivedSources/resource_bundle_accessor.swift' \
        -print -quit
)"
if [[ -z "$resource_accessor" ]]; then
    echo "Entwicklungs-Build abgebrochen: SwiftPM-Ressourcenzugriff fehlt." >&2
    exit 1
fi
perl -0pi -e \
    's/Bundle\.main\.bundleURL/Bundle.main.resourceURL!/g' \
    "$resource_accessor"
touch "$resource_accessor"

swift build \
    --package-path "$root_directory" \
    --scratch-path "$scratch_directory" \
    --configuration release

binary_directory="$(
    swift build \
        --package-path "$root_directory" \
        --scratch-path "$scratch_directory" \
        --configuration release \
        --show-bin-path
)"

rm -rf "$output_directory"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cp "$binary_directory/AppAtlas" "$app_bundle/Contents/MacOS/AppAtlas"
cp -R \
    "$binary_directory/AppAtlas_AppAtlas.bundle" \
    "$app_bundle/Contents/Resources/AppAtlas_AppAtlas.bundle"
cp \
    "$root_directory/Sources/AppAtlas/Resources/AppIcon.icns" \
    "$app_bundle/Contents/Resources/AppIcon.icns"
cp "$root_directory/LICENSE" "$app_bundle/Contents/Resources/LICENSE.txt"

build_resource_path="$binary_directory/AppAtlas_AppAtlas.bundle"
BUILD_RESOURCE_PATH="$build_resource_path" perl -0pi -e '
    $replacement = "AppAtlas_AppAtlas.bundle";
    $replacement .= "\0" x (
        length($ENV{"BUILD_RESOURCE_PATH"}) - length($replacement)
    );
    s/\Q$ENV{"BUILD_RESOURCE_PATH"}\E/$replacement/g;
' "$app_bundle/Contents/MacOS/AppAtlas"

sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__BUILD_NUMBER__/$build_number/g" \
    "$root_directory/Packaging/Info.plist" \
    > "$app_bundle/Contents/Info.plist"

plutil -lint "$app_bundle/Contents/Info.plist"
sign_identity="${APPATLAS_SIGN_IDENTITY:-}"
if [[ -z "$sign_identity" ]]; then
    sign_identity=$(
        security find-identity -v -p codesigning 2>/dev/null \
            | awk -F '"' '/Apple Development:/ { print $2; exit }'
    )
fi
if [[ -z "$sign_identity" ]]; then
    sign_identity="-"
fi
codesign \
    --force \
    --deep \
    --sign "$sign_identity" \
    --entitlements "$root_directory/Packaging/AppAtlas.entitlements" \
    "$app_bundle"
codesign --verify --deep --strict "$app_bundle"

echo "Entwicklungs-App erstellt:"
echo "  $app_bundle"
