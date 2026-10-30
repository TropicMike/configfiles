#!/bin/bash
# Make Home/End move to the beginning/end of the line (and Ctrl+Home/End to
# the beginning/end of the document) in Cocoa apps, instead of scrolling.
# Takes effect in apps launched after this runs.
set -eu
mkdir -p ~/Library/KeyBindings
cat > ~/Library/KeyBindings/DefaultKeyBinding.dict <<'EOF'
{
  "\UF729" = "moveToBeginningOfLine:";
  "\UF72B" = "moveToEndOfLine:";
  "$\UF729" = "moveToBeginningOfLineAndModifySelection:";
  "$\UF72B" = "moveToEndOfLineAndModifySelection:";
  "^\UF729" = "moveToBeginningOfDocument:";
  "^\UF72B" = "moveToEndOfDocument:";
  "$^\UF729" = "moveToBeginningOfDocumentAndModifySelection:";
  "$^\UF72B" = "moveToEndOfDocumentAndModifySelection:";
}
EOF
