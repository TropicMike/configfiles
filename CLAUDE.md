# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal configuration files repository containing dotfiles, system configurations, and utility scripts for Linux, macOS, and Windows environments. Files are deployed to their target systems via the `deploy.sh` / `deploy.bat` scripts; they are version controlled for backup and synchronization across systems, not built or tested programmatically.

## Repository Structure

### Shared Configuration (repo root)
- `.aliases` - Shared aliases and shell functions, sourced by both bash and zsh:
  - Cross-platform editor detection (macOS Emacs.app GUI, standard emacs, or nano fallback)
  - Common command shortcuts (`m`, `z`, `md`, `e`, etc.)
  - OS-aware `ls`/`lsd`, plus utilities (`hex`, `ntop`/`bmon`, `ipa`, `rmbak`)
  - Once-daily background check for new upstream commits to this repo (`~/Repos/configfiles`), printing a pull + deploy reminder; throttled via a stamp file in `~/.cache`
- `.emacs` - Emacs initialization: wombat theme, cross-platform mono font, sh-mode for `.aliases`, 120x40 window, `uniq-lines` alias for `delete-duplicate-lines`

### Linux/
- `.bashrc` - Bash initialization: guards against non-interactive shells, sets PATH, sources `.aliases`, sets prompt (red for root, green for user)

### MacOS/
- `.zshrc` - Zsh initialization: sets PATH, sources `.aliases`, sets prompt (red for root, green for user)
- `macos-fix-home-end.sh` - Remaps Home/End keys to beginning/end of line via `DefaultKeyBinding.dict`

### Windows/
- `aliases.bat` - DOS command aliases (`ls`, `cp`, `xcp`, `mv`, `clear`, `h`, `alias`)
- `netlogon.bat` - Network logon script
- `run-bi.bat` - BI application launcher
- `MJS - fix passwordless login.bat` - Passwordless login fix script
- `hitman2-keys.reg` - Game-specific key bindings registry file
- `right-click/` - Registry files to enable/disable the Windows context menu:
  - `enable_right_click_Allusers.reg` / `disable_right_click_Allusers.reg`
  - `enable_right_click_Currentuser.reg` / `disable_right_click_Currentuser.reg`

### Deploy Scripts
- `deploy.sh` - Deploys shared + OS-specific files on Linux/macOS. Backs up existing files (`.bak`), skips unchanged, and can re-source changed shell files. Run with `sudo` to deploy to root's home directory.
- `deploy.bat` - Windows equivalent (`.emacs`, `aliases.bat`).

## Working with This Repository

When modifying files:
- Keep the editor-detection logic in `.aliases` cross-platform (macOS GUI, generic, nano fallback)
- `.aliases` is sourced by both bash and zsh — keep it POSIX-portable across the two
- Line endings and encodings are enforced by `.gitattributes`:
  - Shell scripts and dotfiles use Unix line endings (LF)
  - Batch files use DOS line endings (CRLF)
  - Registry files use UTF-16 encoding with BOM
- Maintain existing alias naming conventions and patterns

Deployment is driven by `deploy.sh` (Linux/macOS) and `deploy.bat` (Windows), which back up existing files before overwriting.
