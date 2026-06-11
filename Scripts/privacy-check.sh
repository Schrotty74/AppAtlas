#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_directory"

candidate_files=("${(@f)$(git ls-files --cached --others --exclude-standard)}")
for file in "${candidate_files[@]}"; do
    [[ -f "$file" ]] || continue
    normalized_file="${(L)file}"
    case "$normalized_file" in
        *.csv|*.tsv|*.db|*.sqlite|*.sqlite3|*.private.json|\
        */catalog.json|*/catalog-*.json|*/katalog.json|*/katalog-*.json|\
        */export-*.json|*/appatlas-katalog*.json|*/appatlas-catalog*.json)
            echo "Datenschutzprüfung fehlgeschlagen: private Datei: $file" >&2
            exit 1
            ;;
    esac
done

content_files=("${(@)candidate_files:#Scripts/privacy-check.sh}")
if grep -I -n -E '/Users/[^/]+|/Volumes/[^/]+|serialNumber[[:space:]]*[:=][[:space:]]*"[^"]+' \
    "${content_files[@]}" >/tmp/appatlas-privacy-check.txt 2>/dev/null; then
    cat /tmp/appatlas-privacy-check.txt >&2
    echo "Datenschutzprüfung fehlgeschlagen: persönlicher Pfad oder Geheimnis gefunden." >&2
    exit 1
fi

echo "Datenschutzprüfung erfolgreich."
