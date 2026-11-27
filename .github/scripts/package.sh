#!/usr/bin/env bash
# Builds the addon zip and the release notes for a tag.
# Usage: package.sh <tag> [output dir]
#   package.sh v1.0.0  ->  .release/FieldGuide-1.0.0.zip + .release/RELEASE_NOTES.md
#
# Repository layout: the addon lives in its own folder (FieldGuide/),
# GitHub files (README, LICENSE, workflows...) stay at the root and are not packaged.
set -euo pipefail

ADDON="FieldGuide"
TAG="${1:?usage: package.sh <tag> [output dir]}"
OUT="${2:-.release}"
VERSION="${TAG#v}"

if [ ! -f "$ADDON/$ADDON.toc" ]; then
    echo "error: $ADDON/$ADDON.toc not found (run from the repository root)" >&2
    exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

# Only tracked files of the addon folder go into the zip
git ls-files -- "$ADDON" | while IFS= read -r file; do
    mkdir -p "$OUT/$(dirname "$file")"
    cp "$file" "$OUT/$file"
done

# Version from the tag (overrides the version written in the .toc)
sed -i "s/@project-version@/${VERSION}/g; s/^## Version:.*/## Version: ${VERSION}/" "$OUT/$ADDON/$ADDON.toc"
if grep -rq "@project-version@" "$OUT/$ADDON"; then
    echo "error: @project-version@ left in the package" >&2
    exit 1
fi

(cd "$OUT" && zip -rq "$ADDON-$VERSION.zip" "$ADDON")

# Release notes: commits since the previous tag
PREVIOUS="$(git describe --tags --abbrev=0 "${TAG}^" 2>/dev/null || true)"
RANGE="$TAG"
[ -n "$PREVIOUS" ] && RANGE="$PREVIOUS..$TAG"
{
    echo "## $ADDON $VERSION"
    echo
    git log --no-merges --pretty='- %s' "$RANGE"
    if [ -n "$PREVIOUS" ]; then
        echo
        echo "Changes since $PREVIOUS."
    fi
} > "$OUT/RELEASE_NOTES.md"

echo "Built $OUT/$ADDON-$VERSION.zip"
