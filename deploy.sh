#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGED_SHELL_FILES=()

if [ "$(id -u)" -eq 0 ]; then
  DEPLOY_HOME="$(eval echo ~root)"
else
  DEPLOY_HOME="$HOME"
fi

backup_and_copy() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    echo "  SKIP $(basename "$src") (not found)"
    return
  fi
  if [ -f "$dest" ] && diff -q "$src" "$dest" >/dev/null 2>&1; then
    echo "  UNCHANGED $(basename "$dest")"
    return
  fi
  if [ -f "$dest" ]; then
    cp "$dest" "$dest.bak"
    echo "  BACKUP $dest -> $dest.bak"
  fi
  cp "$src" "$dest"
  echo "  INSTALLED $dest"
  CHANGED_SHELL_FILES+=("$dest")
}

echo "Deploying config files to $DEPLOY_HOME"
echo "OS: $(uname)"
echo ""

backup_and_copy "$SCRIPT_DIR/.aliases" "$DEPLOY_HOME/.aliases"
backup_and_copy "$SCRIPT_DIR/.emacs" "$DEPLOY_HOME/.emacs"

case "$(uname)" in
  Linux)
    backup_and_copy "$SCRIPT_DIR/Linux/.bashrc" "$DEPLOY_HOME/.bashrc"
    ;;
  Darwin)
    backup_and_copy "$SCRIPT_DIR/OSX/.zshrc" "$DEPLOY_HOME/.zshrc"
    ;;
  *)
    echo "  WARNING: Unknown OS '$(uname)', only shared files deployed"
    ;;
esac

echo ""

# Determine sourceable files (exclude .emacs which can't be shell-sourced)
SOURCEABLE=()
for f in "${CHANGED_SHELL_FILES[@]}"; do
  case "$f" in
    *.emacs) ;;
    *) SOURCEABLE+=("$f") ;;
  esac
done

if [ ${#SOURCEABLE[@]} -gt 0 ]; then
  # Detect if this script is being sourced
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    for f in "${SOURCEABLE[@]}"; do
      # shellcheck disable=SC1090
      source "$f"
      echo "  SOURCED $f"
    done
  else
    echo "To activate changes, run:"
    for f in "${SOURCEABLE[@]}"; do
      echo "  source $f"
    done
    echo ""
  fi
fi

echo "Done."
