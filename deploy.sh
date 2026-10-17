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
FAILED=0

# Detect if this script is being sourced (bash compares BASH_SOURCE to $0;
# zsh reports ":file" in ZSH_EVAL_CONTEXT while sourcing). Done up front
# because the two modes differ in behavior below — in particular, an exit
# code must never be propagated out of a sourced script, where it would kill
# the caller's shell.
SOURCED=0
if [ -n "${ZSH_VERSION:-}" ]; then
  case "${ZSH_EVAL_CONTEXT:-}" in *:file*) SOURCED=1 ;; esac
elif [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
  SOURCED=1
fi

if [ "$(id -u)" -eq 0 ]; then
  DEPLOY_HOME="$(eval echo ~root)"
else
  DEPLOY_HOME="$HOME"
fi

# Print the path a (possibly symlinked) destination ultimately points to, so
# an install via mv updates the link's target instead of replacing the link
# with a regular file. Done by hand because readlink -f isn't portable.
resolve_symlinks() {
  local path="$1" link n=0
  while [ -L "$path" ] && [ "$n" -lt 40 ]; do
    link="$(readlink "$path")"
    case "$link" in
      /*) path="$link" ;;
      *) path="$(dirname "$path")/$link" ;;
    esac
    n=$((n + 1))
  done
  echo "$path"
}

backup_and_copy() {
  local src="$1" dest="$2" orig_dest="$2" tmp
  if [ ! -f "$src" ]; then
    echo "  SKIP $(basename "$src") (not found)"
    return
  fi
  dest="$(resolve_symlinks "$dest")"
  if [ -f "$dest" ] && diff -q "$src" "$dest" >/dev/null 2>&1; then
    echo "  UNCHANGED $(basename "$dest")"
    return
  fi
  if [ -f "$dest" ] && [ ! -w "$dest" ]; then
    echo "  ERROR $dest is not writable (fix its permissions and re-run)"
    FAILED=1
    return 1
  fi
  if ! mkdir -p "$(dirname "$dest")"; then
    echo "  ERROR creating $(dirname "$dest")"
    FAILED=1
    return 1
  fi
  # Copy to a temp file next to the destination and move it into place, so a
  # failed or interrupted copy can never leave a truncated file at $dest.
  # mktemp creates the temp file 0600, so remove it and recreate it via cp to
  # inherit the permissions a plain cp to $dest would have produced (the
  # destination's own mode when it exists, else the source's).
  tmp="$(mktemp "$dest.XXXXXX")" || {
    echo "  ERROR creating temp file for $dest"
    FAILED=1
    return 1
  }
  rm -f "$tmp"
  if [ -f "$dest" ]; then
    if ! cp "$dest" "$dest.bak"; then
      rm -f "$tmp"
      echo "  ERROR backing up $dest (leaving it untouched)"
      FAILED=1
      return 1
    fi
    echo "  BACKUP $dest -> $dest.bak"
    # Seed the temp file from the destination for its permissions; if this
    # fails the next cp recreates it from the source instead.
    cp "$dest" "$tmp" 2>/dev/null
  fi
  if ! cp "$src" "$tmp"; then
    rm -f "$tmp"
    echo "  ERROR copying $src -> $dest"
    FAILED=1
    return 1
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "  ERROR installing $dest"
    FAILED=1
    return 1
  fi
  echo "  INSTALLED $dest"
  CHANGED_SHELL_FILES+=("$orig_dest")
}

# Deep-merge a JSON snippet into an existing JSON file (snippet keys win),
# leaving the destination's other settings intact. Requires jq.
merge_json() {
  local src="$1" dest="$2" tmp
  if [ ! -f "$src" ]; then
    echo "  SKIP $(basename "$src") (not found)"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "  SKIP $(basename "$src") (jq not installed)"
    return
  fi
  if [ -f "$dest" ] && [ ! -w "$dest" ]; then
    echo "  ERROR $dest is not writable (fix its permissions and re-run)"
    FAILED=1
    return 1
  fi
  # Validate the snippet up front so a merge failure below can only mean the
  # existing destination is bad.
  if ! jq empty "$src" 2>/dev/null; then
    echo "  SKIP $(basename "$src") (not valid JSON)"
    return
  fi
  dest="$(resolve_symlinks "$dest")"
  if ! mkdir -p "$(dirname "$dest")"; then
    echo "  ERROR creating $(dirname "$dest")"
    FAILED=1
    return 1
  fi
  tmp="$(mktemp "$dest.XXXXXX")" || {
    echo "  ERROR creating temp file for $dest"
    FAILED=1
    return 1
  }
  if [ -f "$dest" ]; then
    if ! jq -s '.[0] * .[1]' "$dest" "$src" >"$tmp" 2>/dev/null; then
      rm -f "$tmp"
      echo "  SKIP $dest (existing file is not valid JSON)"
      return
    fi
  else
    if ! jq . "$src" >"$tmp"; then
      rm -f "$tmp"
      echo "  ERROR merging $src -> $dest"
      FAILED=1
      return 1
    fi
  fi
  if [ -f "$dest" ] && diff -q "$tmp" "$dest" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "  UNCHANGED $(basename "$dest")"
    return
  fi
  if [ -f "$dest" ]; then
    if ! cp "$dest" "$dest.bak"; then
      rm -f "$tmp"
      echo "  ERROR backing up $dest (leaving it untouched)"
      FAILED=1
      return 1
    fi
    echo "  BACKUP $dest -> $dest.bak"
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "  ERROR installing $dest"
    FAILED=1
    return 1
  fi
  echo "  MERGED $src -> $dest"
}

echo "Deploying config files to $DEPLOY_HOME"
echo "OS: $(uname)"
if [ "$(id -u)" -ne 0 ]; then
  echo "Note: to install the files for the root user, re-run with sudo (sudo ./deploy.sh)"
fi
echo ""

backup_and_copy "$SCRIPT_DIR/.aliases" "$DEPLOY_HOME/.aliases"
backup_and_copy "$SCRIPT_DIR/.emacs" "$DEPLOY_HOME/.emacs"
merge_json "$SCRIPT_DIR/claude-prompt.json" "$DEPLOY_HOME/.claude/settings.json"

# OpenCode reads its global config from $XDG_CONFIG_HOME/opencode (default
# ~/.config/opencode). Ignore XDG_CONFIG_HOME under sudo, where it would point
# at the invoking user's config rather than root's.
if [ "$(id -u)" -eq 0 ]; then
  OPENCODE_DIR="$DEPLOY_HOME/.config/opencode"
else
  OPENCODE_DIR="${XDG_CONFIG_HOME:-$DEPLOY_HOME/.config}/opencode"
fi
# Only deploy if OpenCode is installed: on PATH, or in its installer's default
# location (~/.opencode/bin, which may not be on PATH yet, e.g. under sudo or
# before the new rc file is sourced).
if command -v opencode >/dev/null 2>&1 || [ -x "$DEPLOY_HOME/.opencode/bin/opencode" ]; then
  backup_and_copy "$SCRIPT_DIR/opencode/opencode.jsonc" "$OPENCODE_DIR/opencode.jsonc"
else
  echo "  SKIP opencode.jsonc (opencode not installed)"
fi

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

# Determine sourceable files (exclude non-shell configs like .emacs)
SOURCEABLE=()
for f in "${CHANGED_SHELL_FILES[@]}"; do
  case "$f" in
    *.emacs|*.jsonc) ;;
    *) SOURCEABLE+=("$f") ;;
  esac
done

if [ ${#SOURCEABLE[@]} -gt 0 ]; then
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

if [ "$FAILED" -eq 1 ]; then
  echo "Done, with errors (see the ERROR lines above)."
  # Only propagate a failure exit code when executed; exiting from a sourced
  # script would kill the caller's interactive shell.
  if [ "$SOURCED" -eq 0 ]; then
    exit 1
  fi
else
  echo "Done."
fi
