#!/bin/bash
# Bump version number in SKILL.md frontmatter.
# Usage:
#   bump-version.sh patch    # 1.0.0 → 1.0.1 (bugfix/improvement)
#   bump-version.sh minor    # 1.0.0 → 1.1.0 (new feature)
#   bump-version.sh major    # 1.0.0 → 2.0.0 (breaking change)
#   bump-version.sh          # default: patch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/../SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo "ERROR: SKILL.md not found at $SKILL_FILE"
  exit 1
fi

# Extract version from YAML frontmatter (between --- delimiters)
CURRENT=$(awk '/^---/{f++; next} f==1 && /^version:/{print $2; exit}' "$SKILL_FILE")
if [ -z "$CURRENT" ]; then
  echo "ERROR: 'version:' not found in SKILL.md frontmatter"
  exit 1
fi

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

# Update version in SKILL.md frontmatter
sed -i "0,/^version:.*/s/^version:.*/version: $NEW/" "$SKILL_FILE"

echo "$CURRENT → $NEW"
