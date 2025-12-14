#!/bin/bash

# Script to fix common compilation errors in offline mode implementation

echo "Fixing offline mode compilation errors..."

# Fix table accessor names
echo "1. Fixing table accessor names..."
find lib -name "*.dart" -type f -exec sed -i '' 's/_database\.syncQueueTable/_database.syncQueue/g' {} \;
find lib -name "*.dart" -type f -exec sed -i '' 's/_database\.syncMetadataTable/_database.syncMetadata/g' {} \;
find lib -name "*.dart" -type f -exec sed -i '' 's/_database\.idMappingTable/_database.idMapping/g' {} \;

# Fix companion class names
echo "2. Fixing companion class names..."
find lib -name "*.dart" -type f -exec sed -i '' 's/SyncQueueTableCompanion/SyncQueueEntityCompanion/g' {} \;
find lib -name "*.dart" -type f -exec sed -i '' 's/SyncMetadataTableCompanion/SyncMetadataEntityCompanion/g' {} \;
find lib -name "*.dart" -type f -exec sed -i '' 's/IdMappingTableCompanion/IdMappingEntityCompanion/g' {} \;

# Fix exception parameters (originalException -> context map)
echo "3. Fixing exception parameters..."
find lib/services/sync -name "*.dart" -type f -exec sed -i '' 's/originalException: e,/{"error": e.toString()},/g' {} \;
find lib/services/sync -name "*.dart" -type f -exec sed -i '' 's/originalException: error,/{"error": error.toString()},/g' {} \;

# Add missing Drift import where needed
echo "4. Adding missing imports..."
for file in lib/services/sync/*.dart lib/services/id_mapping/*.dart; do
  if [ -f "$file" ]; then
    if grep -q "OrderingTerm\|OrderingMode" "$file" 2>/dev/null; then
      if ! grep -q "package:drift/drift.dart" "$file" 2>/dev/null; then
        # Add import after first import line
        sed -i '' '1a\
import '\''package:drift/drift.dart'\'';
' "$file"
      fi
    fi
  fi
done

echo "Done! Run 'dart analyze' to check for remaining errors."
