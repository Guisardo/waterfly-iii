#!/bin/bash
# Patch script for isar_community_generator 3.3.0 to work with analyzer 8.4.1
# This script patches TypeChecker.fromRuntime to TypeChecker.fromUrl

set -e  # Exit on error

ISAR_GEN_BASE="$HOME/.pub-cache/hosted/pub.dev/isar_community_generator-3.3.0/lib/src"

echo "Patching isar_community_generator for analyzer 8.4.1 compatibility..."

# Check if the base directory exists
if [ ! -d "$ISAR_GEN_BASE" ]; then
  echo "Warning: isar_community_generator not found at $ISAR_GEN_BASE"
  echo "This may be normal if packages haven't been fetched yet."
  echo "Make sure to run 'flutter pub get' first."
  exit 0  # Don't fail, as this might be expected in CI before pub get
fi

PATCHED_COUNT=0

# Patch helper.dart
if [ -f "$ISAR_GEN_BASE/helper.dart" ]; then
  python3 << PYTHON
import os
file_path = os.path.expanduser("$ISAR_GEN_BASE/helper.dart")
with open(file_path, 'r') as f:
    content = f.read()

# Replace TypeChecker.fromRuntime with TypeChecker.fromUrl
replacements = {
    'TypeChecker.fromRuntime(Collection)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Collection')",
    'TypeChecker.fromRuntime(Enumerated)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Enumerated')",
    'TypeChecker.fromRuntime(Embedded)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Embedded')",
    'TypeChecker.fromRuntime(Ignore)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Ignore')",
    'TypeChecker.fromRuntime(Name)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Name')",
    'TypeChecker.fromRuntime(Index)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Index')",
    'TypeChecker.fromRuntime(Backlink)': "TypeChecker.fromUrl('package:isar_community/isar.dart#Backlink')",
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(file_path, 'w') as f:
    f.write(content)
print("✓ Patched helper.dart")
PYTHON
  echo "✓ Patched helper.dart"
  PATCHED_COUNT=$((PATCHED_COUNT + 1))
else
  echo "⚠ helper.dart not found (may already be patched or package not installed)"
fi

# Patch isar_type.dart
if [ -f "$ISAR_GEN_BASE/isar_type.dart" ]; then
  python3 << PYTHON
import os
file_path = os.path.expanduser("$ISAR_GEN_BASE/isar_type.dart")
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace(
    'TypeChecker.fromRuntime(DateTime)',
    "TypeChecker.fromUrl('dart:core#DateTime')"
)

with open(file_path, 'w') as f:
    f.write(content)
print("✓ Patched isar_type.dart")
PYTHON
  echo "✓ Patched isar_type.dart"
  PATCHED_COUNT=$((PATCHED_COUNT + 1))
else
  echo "⚠ isar_type.dart not found (may already be patched or package not installed)"
fi

if [ $PATCHED_COUNT -eq 0 ]; then
  echo "⚠ No files were patched. This may indicate:"
  echo "  1. Packages haven't been fetched (run 'flutter pub get')"
  echo "  2. Files are already patched"
  echo "  3. Package version is different than expected"
else
  echo "✓ Successfully patched $PATCHED_COUNT file(s)"
fi

echo ""
echo "Patching complete! You can now run: dart run build_runner build --delete-conflicting-outputs"
echo "See docs/BUILD_RUNNER_WORKAROUND.md for more information."

