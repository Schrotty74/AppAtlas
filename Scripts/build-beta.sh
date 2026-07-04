#!/bin/zsh

set -euo pipefail

root_directory="$(cd "$(dirname "$0")/.." && pwd)"
exec "$root_directory/Scripts/build-release-package.sh" beta
