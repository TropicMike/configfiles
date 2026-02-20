# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal configuration files repository containing dotfiles, system configurations, and utility scripts for both Linux/Unix and Windows environments. Files are meant to be manually deployed to their respective target systems, not built or tested programmatically.

## Repository Structure

### Shell Configuration (Linux/Unix)
- `.bashrc` - Bash initialization, sets PATH and sources .aliases
- `.bashrc_root` - Root user bash configuration (if it exists)
- `.aliases` - Bash aliases and shell functions, includes:
  - Editor detection and configuration (snap emacs, standard emacs, or nano fallback)
  - Common command shortcuts (m, z, md, e, etc.)
  - Utility aliases (hex, vnc, ntop/bmon)

### Editor Configuration
- `.emacs` - Emacs initialization with custom settings:
  - Wombat theme, syntax highlighting, line numbers
  - Custom window dimensions (120x40)
  - Custom `uniq-lines` function for removing duplicate lines in region

### Windows Configuration
- `aliases.bat` - DOS command aliases (ls, cp, mv, clear, etc.)
- Various `.bat` utility scripts for system configuration

### Windows Registry Files
- `hitman2-keys.reg` - Game-specific key bindings
- `right-click/` folder contains registry files to enable/disable Windows context menus:
  - `enable_right_click_Allusers.reg` / `disable_right_click_Allusers.reg`
  - `enable_right_click_Currentuser.reg` / `disable_right_click_Currentuser.reg`

### Utility Scripts
- `restart-wifi.sh` - Linux script to restart brcmfmac WiFi driver
- `start_portainer.sh` - Docker Portainer startup
- `upgrade_portainer.txt` - Step-by-step Docker commands for upgrading Portainer

## Working with This Repository

When modifying files:
- Shell configs should maintain the editor detection logic in .aliases
- Registry files use UTF-16 encoding with BOM
- Batch files should preserve DOS line endings (CRLF)
- Shell scripts should use Unix line endings (LF)
- Maintain existing alias naming conventions and patterns

Configuration deployment is manual - these files are version controlled for backup and synchronization across systems, not for automated installation.
