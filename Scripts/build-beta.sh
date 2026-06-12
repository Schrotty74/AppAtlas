#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
version="${APPATLAS_VERSION:-1.0.0-dev}"
build_number="${APPATLAS_BUILD_NUMBER:-33}"
scratch_directory="$root_directory/.build/beta"
release_directory="$root_directory/dist/AppAtlas-$version"
app_bundle="$release_directory/AppAtlas.app"
zip_file="$root_directory/dist/AppAtlas-$version-macos.zip"
checksum_file="$zip_file.sha256"

"$root_directory/Scripts/privacy-check.sh"

swift build \
    --package-path "$root_directory" \
    --scratch-path "$scratch_directory" \
    --configuration release \
    -Xswiftc -F \
    -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -F \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -rpath \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -rpath \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib

binary_directory="$(
    swift build \
        --package-path "$root_directory" \
        --scratch-path "$scratch_directory" \
        --configuration release \
        --show-bin-path
)"

rm -rf "$release_directory" "$zip_file" "$checksum_file"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"

cp "$binary_directory/AppAtlas" "$app_bundle/Contents/MacOS/AppAtlas"
cp -R \
    "$binary_directory/AppAtlas_AppAtlas.bundle" \
    "$app_bundle/Contents/Resources/AppAtlas_AppAtlas.bundle"
cp \
    "$root_directory/Sources/AppAtlas/Resources/AppIcon.icns" \
    "$app_bundle/Contents/Resources/AppIcon.icns"
for localization in de en; do
    localization_directory="$root_directory/Sources/AppAtlas/Resources/$localization.lproj"
    if [[ -d "$localization_directory" ]]; then
        cp -R "$localization_directory" "$app_bundle/Contents/Resources/"
    fi
done
cp "$root_directory/LICENSE" "$app_bundle/Contents/Resources/LICENSE.txt"
find "$app_bundle" -type f \
    -iname 'AppAtlas-Startkatalog-*.tsv' \
    -delete

private_file="$(
    find "$app_bundle" -type f \
        \( -iname '*.tsv' -o -iname '*.private.json' \
        -o -iname '*.private.csv' -o -iname 'catalog.json' \) \
        -print -quit
)"
if [[ -n "$private_file" ]]; then
    echo "Build abgebrochen: private Datei im App-Bundle: $private_file" >&2
    exit 1
fi

sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__BUILD_NUMBER__/$build_number/g" \
    "$root_directory/Packaging/Info.plist" \
    > "$app_bundle/Contents/Info.plist"

plutil -lint "$app_bundle/Contents/Info.plist"
codesign \
    --force \
    --deep \
    --sign - \
    --entitlements "$root_directory/Packaging/AppAtlas.entitlements" \
    "$app_bundle"
codesign --verify --deep --strict "$app_bundle"

ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$zip_file"
(
    cd "$root_directory/dist"
    shasum -a 256 "$(basename "$zip_file")" \
        > "$(basename "$checksum_file")"
)

echo "Beta erstellt:"
echo "  $app_bundle"
echo "  $zip_file"
echo "  $checksum_file"
