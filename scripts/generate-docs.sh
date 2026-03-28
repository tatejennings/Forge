#!/bin/bash
# generate-docs.sh — Generates the Forge DocC static site into docs/.
# Usage: ./scripts/generate-docs.sh
#
# The swift-docc-plugin is NOT declared in Package.swift (to avoid burdening
# consumers). This script temporarily patches the manifest to add the plugin
# and include the .docc catalog, generates docs, then restores the original.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔨 Generating Forge documentation..."

# Check for Swift toolchain
if ! command -v swift &> /dev/null; then
    echo "❌ Swift toolchain not found. Make sure Xcode is installed and swift is on your PATH."
    exit 1
fi

# Patch Package.swift: add the docc plugin and remove the Forge.docc exclude.
# The original is restored on exit (success or failure) via trap.
cp Package.swift Package.swift.bak
TMPDIR_DOCS=$(mktemp -d)
trap 'mv Package.swift.bak Package.swift; rm -rf "$TMPDIR_DOCS"' EXIT

DOCC_DEP='\ \ \ \ dependencies: [\
        .package(url: "https:\/\/github.com\/swiftlang\/swift-docc-plugin", from: "1.4.3"),\
    ],'

# 1. Insert docc-plugin dependency before the top-level "targets:" key.
#    Match only the first occurrence (the package-level one) by checking indentation.
sed -i '' "/^    targets: \[/i\\
$DOCC_DEP
" Package.swift

# 2. Remove the Forge.docc exclude so DocC can find the catalog.
sed -i '' '/exclude: \["Forge.docc"\]/d' Package.swift

# Clean existing output
echo "🗑️  Cleaning existing docs/..."
rm -rf docs

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
