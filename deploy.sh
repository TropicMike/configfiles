#!/bin/bash
# May be executed (bash) or sourced from bash OR zsh (zsh is the macOS default
# shell), so resolve this script's path in a way that works for all three.
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  _self="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296  # zsh-only expansion, guarded by ZSH_VERSION
  _self="${(%):-%x}"  # zsh: path of the file currently being sourced
else
  _self="$0"
fi
SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
unset _self
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
if [ "$(id -u)" -ne 0 ]; then
  echo "Note: to install the files for the root user, re-run with sudo (sudo ./deploy.sh)"
fi
echo ""

backup_and_copy "$SCRIPT_DIR/.aliases" "$DEPLOY_HOME/.aliases"
backup_and_copy "$SCRIPT_DIR/.emacs" "$DEPLOY_HOME/.emacs"

case "$(uname)" in
  Linux)
    backup_and_copy "$SCRIPT_DIR/Linux/.bashrc" "$DEPLOY_HOME/.bashrc"
    ;;
  Darwin)
    backup_and_copy "$SCRIPT_DIR/MacOS/.zshrc" "$DEPLOY_HOME/.zshrc"
    ;;
  MINGW*|MSYS*)
    # Git Bash on Windows sources ~/.bashrc like Linux (via /etc/profile).
    backup_and_copy "$SCRIPT_DIR/Linux/.bashrc" "$DEPLOY_HOME/.bashrc"
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
  # Detect if this script is being sourced (bash compares BASH_SOURCE to $0;
  # zsh reports ":file" in ZSH_EVAL_CONTEXT while sourcing).
  SOURCED=0
  if [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in *:file*) SOURCED=1 ;; esac
  elif [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    SOURCED=1
  fi
  if [ "$SOURCED" -eq 1 ]; then
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
