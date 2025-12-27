#!/bin/bash
# Post-build script to fix null-aware-elements syntax in generated json_serializable files
# Converts ?instance.field to instance?.field for Dart 3.7.0 compatibility

find .dart_tool/build/generated -name "*json_serializable.g.part" 2>/dev/null | while read file; do
  # Replace ?instance.field with instance?.field (null-aware spread to null-aware member access)
  # Pattern matches: 'key': ?instance.field, or 'key': ?instance.field
  # This converts Dart 3.8+ null-aware-elements syntax to Dart 3.7.0 compatible syntax
  perl -i -pe 's/(\x27[^\x27]*\x27:\s*)\?instance\.(\w+)/$1instance?.$2/g; s/(\x27[^\x27]*\x27:\s*)\?json\.(\w+)/$1json?.$2/g; s/(\x27[^\x27]*\x27:\s*)\?e\.(\w+)/$1e?.$2/g' "$file"
done

echo "Fixed generated json_serializable files"

