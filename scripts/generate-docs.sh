#!/bin/bash
# generate-docs.sh — Generates the Forge DocC static site into docs/.
# Usage: ./generate-docs.sh

set -e

echo "🔨 Generating Forge documentation..."

# Check for Swift toolchain
if ! command -v swift &> /dev/null; then
    echo "❌ Swift toolchain not found. Make sure Xcode is installed and swift is on your PATH."
    exit 1
fi

# Clean existing output
echo "🗑️  Cleaning existing docs/..."
rm -rf docs

# Generate into a temp directory first, then move into place.
# This avoids sandbox permission issues where the DocC plugin cannot
# write directly to the project directory on some macOS configurations.
TMPDIR_DOCS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DOCS"' EXIT

echo "📚 Running swift package generate-documentation..."
if ! swift package generate-documentation \
    --target Forge \
    --output-path "$TMPDIR_DOCS" \
    --transform-for-static-hosting \
    --hosting-base-path Forge; then
    echo "❌ Documentation generation failed."
    exit 1
fi

cp -R "$TMPDIR_DOCS" docs

# Verify output
if [ ! -f docs/index.html ]; then
    echo "❌ docs/index.html not found — generation may have failed silently."
    exit 1
fi

echo ""
echo "✅ Documentation generated successfully."
echo ""
echo "   Local:        docs/index.html"
echo "   GitHub Pages: https://tatejennings.github.io/Forge/documentation/forge"

exit 0
