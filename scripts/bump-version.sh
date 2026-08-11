#!/bin/bash
# Bump version number in VERSION file.
# Usage:
#   bump-version.sh patch    # 1.0.0 → 1.0.1 (bugfix/improvement)
#   bump-version.sh minor    # 1.0.0 → 1.1.0 (new feature)
#   bump-version.sh major    # 1.0.0 → 2.0.0 (breaking change)
#   bump-version.sh          # default: patch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../VERSION"

if [ ! -f "$VERSION_FILE" ]; then
  echo "ERROR: VERSION file not found at $VERSION_FILE"
  exit 1
fi

CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

PART="${1:-patch}"
case "$PART" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "Usage: bump-version.sh [major|minor|patch]"
    echo "Current version: $CURRENT"
    exit 1
    ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"
echo -n "$NEW" > "$VERSION_FILE"
echo "$CURRENT → $NEW"
