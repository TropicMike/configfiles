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
# Temp file currently being written, removed by the interrupt trap below.
_TMP=""

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

DRY_RUN=0
for _arg in "$@"; do
  case "$_arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: deploy.sh [-n|--dry-run] [-h|--help]

Installs the shared and OS-specific config files from this repo into your
home directory (root's when run as root/sudo), backing up any file it
replaces to <file>.bak and skipping files that are already up to date.
Installs the Claude Code status line and merges claude-prompt.json into
~/.claude/settings.json (requires jq) when Claude Code is installed, and
installs the OpenCode config if opencode is installed.

  -n, --dry-run  print what would be installed, backed up, or merged,
                 without writing anything
  -h, --help     show this help

May also be sourced (source ./deploy.sh) from bash or zsh, in which case
changed shell files are re-sourced into the current shell.
EOF
      # A top-level return ends a sourced script without killing the caller.
      if [ "$SOURCED" -eq 1 ]; then return 0; else exit 0; fi
      ;;
    *)
      # Sourced, "$@" holds the *caller's* positional parameters, so an
      # unrecognised word is probably not ours: warn and carry on rather than
      # aborting the caller's shell (or worse, returning 2 from their script).
      if [ "$SOURCED" -eq 1 ]; then
        echo "deploy.sh: ignoring unknown argument '$_arg' (sourced)" >&2
      else
        echo "deploy.sh: unknown option '$_arg' (see --help)" >&2
        exit 2
      fi
      ;;
  esac
done
unset _arg

# On Ctrl-C (or kill), remove the half-written temp file instead of leaving it
# next to the destination. Only when executed: a trap set while sourced would
# stay installed in the caller's interactive shell.
if [ "$SOURCED" -eq 0 ]; then
  trap '[ -n "$_TMP" ] && rm -f "$_TMP"; exit 130' INT TERM HUP
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
  if [ "$DRY_RUN" -eq 1 ]; then
    [ -f "$dest" ] && echo "  WOULD BACK UP $dest -> $dest.bak"
    echo "  WOULD INSTALL $dest"
    return
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
  _TMP="$tmp"
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
  _TMP=""
  echo "  INSTALLED $dest"
  CHANGED_SHELL_FILES+=("$orig_dest")
}

# Deep-merge a JSON snippet into an existing JSON file (snippet keys win),
# leaving the destination's other settings intact. Requires jq.
merge_json() {
  local src="$1" dest="$2" tmp merged
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
  if [ "$DRY_RUN" -eq 1 ]; then
    if [ ! -f "$dest" ]; then
      echo "  WOULD CREATE $dest from $src"
    elif ! merged="$(jq -s '.[0] * .[1]' "$dest" "$src" 2>/dev/null)"; then
      echo "  SKIP $dest (existing file is not valid JSON)"
    elif printf '%s\n' "$merged" | diff -q - "$dest" >/dev/null 2>&1; then
      echo "  UNCHANGED $(basename "$dest")"
    else
      echo "  WOULD BACK UP $dest -> $dest.bak"
      echo "  WOULD MERGE $src -> $dest"
    fi
    return
  fi
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
  _TMP="$tmp"
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
  _TMP=""
  echo "  MERGED $src -> $dest"
}

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run: showing what would be deployed to $DEPLOY_HOME (nothing is written)"
else
  echo "Deploying config files to $DEPLOY_HOME"
fi
echo "OS: $(uname)"
if [ "$(id -u)" -ne 0 ]; then
  echo "Note: to install the files for the root user, re-run with sudo (sudo ./deploy.sh)"
fi
echo ""

backup_and_copy "$SCRIPT_DIR/.aliases" "$DEPLOY_HOME/.aliases"
backup_and_copy "$SCRIPT_DIR/.emacs" "$DEPLOY_HOME/.emacs"
# Claude Code's status line: deploy the script and merge the snippet only when
# Claude Code is present — either its binary is on PATH, or ~/.claude already
# exists (which also keeps updating an install whose binary isn't on PATH yet).
if command -v claude >/dev/null 2>&1 || [ -d "$DEPLOY_HOME/.claude" ]; then
  # The status line script that claude-prompt.json's statusLine command runs.
  backup_and_copy "$SCRIPT_DIR/claude-statusline.sh" "$DEPLOY_HOME/.claude/statusline.sh"
  merge_json "$SCRIPT_DIR/claude-prompt.json" "$DEPLOY_HOME/.claude/settings.json"
else
  echo "  SKIP claude-prompt.json (claude not installed)"
fi

# OpenCode reads its global config from $XDG_CONFIG_HOME/opencode (default
# ~/.config/opencode). Ignore XDG_CONFIG_HOME under sudo, where it would point
# at the invoking user's config rather than root's.
if [ "$(id -u)" -eq 0 ]; then
  OPENCODE_DIR="$DEPLOY_HOME/.config/opencode"
else
  OPENCODE_DIR="${XDG_CONFIG_HOME:-$DEPLOY_HOME/.config}/opencode"
fi

# The Obsidian vault — and so the AI-memory notes OpenCode loads from it — lives
# outside this repo, so opencode.jsonc holds a placeholder for its glob that is
# filled in per machine here. $OBSIDIAN_VAULT overrides the search below.
# Prints only the glob on stdout; warnings go to stderr so they can't end up in
# the rendered config. A glob matching nothing is skipped silently by OpenCode,
# so an absent vault has to be reported loudly at deploy time instead.
ai_memory_glob() {
  local vault="" candidate
  if [ -n "${OBSIDIAN_VAULT:-}" ]; then
    vault="${OBSIDIAN_VAULT%/}"
  else
    for candidate in \
      "$DEPLOY_HOME/Documents/MJS-Obsidian-Vault" \
      "$DEPLOY_HOME/Vaults/MJS-Obsidian-Vault" \
      "$DEPLOY_HOME/MJS-Obsidian-Vault"
    do
      if [ -d "$candidate/AI-memory" ]; then
        vault="$candidate"
        break
      fi
    done
    [ -n "$vault" ] || vault="$DEPLOY_HOME/Documents/MJS-Obsidian-Vault"
  fi
  if [ ! -d "$vault/AI-memory" ]; then
    echo "  WARNING: no AI-memory folder at $vault" >&2
    echo "           set OBSIDIAN_VAULT to your vault, or AI memory will not load" >&2
  fi
  # Git Bash reports /c/Users/... ; OpenCode running on Windows needs C:/Users/...
  case "$(uname)" in
    MINGW*|MSYS*)
      if command -v cygpath >/dev/null 2>&1; then
        vault="$(cygpath -m "$vault")"
      fi
      ;;
  esac
  printf '%s/AI-memory/*.md' "$vault"
}

# opencode.jsonc is a template: substitute the placeholder into a temp copy,
# then install that through backup_and_copy so the backup, unchanged-skip and
# atomic install behaviour all still apply.
install_opencode_config() {
  local src="$1" dest="$2" rendered tmpdir glob
  if [ ! -f "$src" ]; then
    echo "  SKIP $(basename "$src") (not found)"
    return
  fi
  tmpdir="$(mktemp -d)" || {
    echo "  ERROR creating temp dir for $(basename "$src")"
    FAILED=1
    return 1
  }
  glob="$(ai_memory_glob)"
  if ! rendered="$(cat "$src")"; then
    echo "  ERROR reading $(basename "$src")"
    FAILED=1
    rm -rf "$tmpdir"
    return 1
  fi
  rendered="${rendered//__AI_MEMORY_GLOB__/$glob}"
  printf '%s\n' "$rendered" > "$tmpdir/opencode.jsonc"
  backup_and_copy "$tmpdir/opencode.jsonc" "$dest"
  rm -rf "$tmpdir"
}

# Only deploy if OpenCode is installed: on PATH, or in its installer's default
# location (~/.opencode/bin, which may not be on PATH yet, e.g. under sudo or
# before the new rc file is sourced).
if command -v opencode >/dev/null 2>&1 || [ -x "$DEPLOY_HOME/.opencode/bin/opencode" ]; then
  install_opencode_config "$SCRIPT_DIR/opencode/opencode.jsonc" "$OPENCODE_DIR/opencode.jsonc"
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

# Determine sourceable files (exclude non-shell configs like .emacs, and
# scripts like the Claude status line that are run, not sourced)
SOURCEABLE=()
for f in "${CHANGED_SHELL_FILES[@]}"; do
  case "$f" in
    *.emacs|*.jsonc|*.sh) ;;
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
elif [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete; nothing was changed."
else
  echo "Done."
fi
