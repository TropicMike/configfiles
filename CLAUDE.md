# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal configuration files repository containing dotfiles, system configurations, and utility scripts for Linux, macOS, and Windows environments. Files are deployed to their target systems via the `deploy.sh` / `deploy.bat` scripts and version controlled for backup and synchronization across systems; there is no build, but CI tests the scripts.

`README.md` is the file inventory (what each file is, what it deploys, and where). Keep it up to date when adding, removing, or changing files rather than duplicating it here.

## Working with This Repository

When modifying files:
- Keep the editor-detection logic in `.aliases` simple: emacs if installed, nano fallback
- `.aliases` is sourced by both bash and zsh — keep it portable across those two shells (bash/zsh constructs like `[[ ]]`, `function`, and `&>` are fine; plain POSIX sh is not a target)
- Line endings and encodings are enforced by `.gitattributes`:
  - Shell scripts and dotfiles use Unix line endings (LF)
  - Batch files and PowerShell scripts use DOS line endings (CRLF)
  - Registry files use UTF-16 encoding with BOM
- Keep `Windows/Microsoft.PowerShell_profile.ps1` compatible with Windows PowerShell 5.1
- Maintain existing alias naming conventions and patterns
- `deploy.sh` and `deploy.bat` are meant to behave alike (backup to `.bak`, skip unchanged, atomic install, exit 1 on failure); change both together
- `deploy.sh` may be sourced from bash or zsh: never `exit` or set traps on the sourced path
- CI (`.github/workflows/ci.yml`) runs shellcheck, bash/zsh syntax + source checks, `deploy.sh` behavior tests on both Linux and macOS runners (the macOS job exercises the Darwin-only branches), and PSScriptAnalyzer on every push — new shell files should be added to those checks

Deployment is driven by `deploy.sh` (Linux/macOS) and `deploy.bat` (Windows), which back up existing files before overwriting.
