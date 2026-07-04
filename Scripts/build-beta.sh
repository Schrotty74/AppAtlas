#!/bin/zsh

set -euo pipefail

if [[ "${APPATLAS_ALLOW_RELEASE_PACKAGE:-}" != "YES" ]]; then
    echo "Release-Paket abgebrochen: ausdrückliche Freigabe fehlt." >&2
    echo "Für normale Prüfungen ausschließlich 'swift build' und 'swift test' verwenden." >&2
    echo "Nur nach Benutzerfreigabe mit APPATLAS_ALLOW_RELEASE_PACKAGE=YES ausführen." >&2
    exit 1
fi

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
version="${APPATLAS_VERSION:-1.0.0-dev}"
build_number="${APPATLAS_BUILD_NUMBER:-33}"
scratch_directory="$root_directory/.build/beta"
release_directory="$root_directory/dist/AppAtlas-$version"
app_bundle="$release_directory/AppAtlas.app"
zip_file="$root_directory/Backup/AppAtlas-$version-macos.zip"
dmg_file="$root_directory/Backup/AppAtlas-$version-macos.dmg"
zip_checksum_file="$zip_file.sha256"
dmg_checksum_file="$dmg_file.sha256"
bundle_identifier="at.schrotty.appatlas"
if [[ "$version" == *beta* ]]; then
    bundle_identifier="at.schrotty.appatlas.beta"
fi

export SWIFTPM_HOME="$root_directory/.build-cache/swiftpm"
export CLANG_MODULE_CACHE_PATH="$root_directory/.build-cache/clang"

"$root_directory/Scripts/privacy-check.sh"
mkdir -p "$root_directory/Backup"

swift build \
    --package-path "$root_directory" \
    --scratch-path "$scratch_directory" \
    --disable-sandbox \
    --configuration release \
    -Xswiftc -F \
    -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -F \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -rpath \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -Xlinker -rpath \
    -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib

resource_accessor="$(
    find "$scratch_directory" \
        -path '*/AppAtlas.build/DerivedSources/resource_bundle_accessor.swift' \
        -print -quit
)"
if [[ -z "$resource_accessor" ]]; then
    echo "Build abgebrochen: SwiftPM-Ressourcenzugriff fehlt." >&2
    exit 1
fi
perl -0pi -e \
    's/Bundle\.main\.bundleURL/Bundle.main.resourceURL!/g' \
    "$resource_accessor"
touch "$resource_accessor"

swift build \
    --package-path "$root_directory" \
    --scratch-path "$scratch_directory" \
    --disable-sandbox \
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
        --disable-sandbox \
        --configuration release \
        --show-bin-path
)"

rm -rf \
    "$release_directory" \
    "$zip_file" \
    "$dmg_file" \
    "$zip_checksum_file" \
    "$dmg_checksum_file"
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

app_binary="$app_bundle/Contents/MacOS/AppAtlas"
private_rpaths=("${(@f)$(
    otool -l "$app_binary" \
        | awk '/^[[:space:]]+path \/(Users|Volumes)\// { print $2 }'
)}")
for private_rpath in "${private_rpaths[@]}"; do
    [[ -n "$private_rpath" ]] || continue
    install_name_tool -delete_rpath "$private_rpath" "$app_binary"
done

strip -S "$app_binary"
build_resource_path="$binary_directory/AppAtlas_AppAtlas.bundle"
BUILD_RESOURCE_PATH="$build_resource_path" perl -0pi -e '
    $replacement = "AppAtlas_AppAtlas.bundle";
    $replacement .= "\0" x (
        length($ENV{"BUILD_RESOURCE_PATH"}) - length($replacement)
    );
    s/\Q$ENV{"BUILD_RESOURCE_PATH"}\E/$replacement/g;
' "$app_binary"
local_path_pattern="/""Users/[^/]+|/""Volumes/[^/]+"
if rg -a "$local_path_pattern" "$app_binary" >/dev/null; then
    echo "Build abgebrochen: lokaler Pfad im App-Binary gefunden." >&2
    exit 1
fi

sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__BUILD_NUMBER__/$build_number/g" \
    -e "s/at.schrotty.appatlas/$bundle_identifier/g" \
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
dmg_staging_directory="$release_directory/DMG"
rm -rf "$dmg_staging_directory"
mkdir -p "$dmg_staging_directory"
cp -R "$app_bundle" "$dmg_staging_directory/AppAtlas.app"
ln -s /Applications "$dmg_staging_directory/Applications"
hdiutil create \
    -volname "AppAtlas $version" \
    -srcfolder "$dmg_staging_directory" \
    -ov \
    -format UDZO \
    "$dmg_file"
(
    cd "$root_directory/Backup"
    shasum -a 256 "$(basename "$zip_file")" \
        > "$(basename "$zip_checksum_file")"
    shasum -a 256 "$(basename "$dmg_file")" \
        > "$(basename "$dmg_checksum_file")"
)

echo "Lokales Release-Paket erstellt (kein Backup):"
echo "  $app_bundle"
echo "  $dmg_file"
echo "  $dmg_checksum_file"
echo "  $zip_file"
echo "  $zip_checksum_file"
