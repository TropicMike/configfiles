#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

backup_and_copy() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    echo "  SKIP $(basename "$src") (not found)"
    return
  fi
  if [ -f "$dest" ]; then
    cp "$dest" "$dest.bak"
    echo "  BACKUP $dest -> $dest.bak"
  fi
  cp "$src" "$dest"
  echo "  INSTALLED $dest"
}

echo "Deploying config files to $HOME"
echo "OS: $(uname)"
echo ""

backup_and_copy "$SCRIPT_DIR/.aliases" "$HOME/.aliases"
backup_and_copy "$SCRIPT_DIR/.emacs" "$HOME/.emacs"

case "$(uname)" in
  Linux)
    backup_and_copy "$SCRIPT_DIR/Linux/.bashrc" "$HOME/.bashrc"
    ;;
  Darwin)
    backup_and_copy "$SCRIPT_DIR/OSX/.zshrc" "$HOME/.zshrc"
    ;;
  *)
    echo "  WARNING: Unknown OS '$(uname)', only shared files deployed"
    ;;
esac

echo ""
echo "Done."
