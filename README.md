# configfiles

Personal configuration files and dotfiles for Linux/Unix and Windows environments. Managed in version control for backup and synchronization across systems. Deployment is manual.

## Files

### Shell Configuration (Linux/Unix)

| File | Description |
|------|-------------|
| `.bashrc` | Bash initialization — sets PATH and sources `.aliases` |
| `.bashrc_root` | Root user bash configuration |
| `.zshrc` | Zsh initialization — sets PATH, sources `.aliases`, sets prompt |
| `.zshrc_root` | Root user zsh configuration |
| `.aliases` | Shared aliases and shell functions (sourced by both bash and zsh) |

#### Aliases / Functions (`.aliases`)

| Alias/Function | Description |
|----------------|-------------|
| `e` | Open editor (emacs via snap, standard emacs, or nano fallback) |
| `m` | `less` |
| `z` | `clear` |
| `md` | `mkdir` |
| `ls` | `ls --color` |
| `lsd` | Long listing with color, sorted by time, paged |
| `rmbak` | Delete `*~` and `#*` backup files in current directory |
| `hex` / `hexdump` | `hexdump -C` |
| `open` | `xdg-open` |
| `vnc` | `vinagre` (suppresses GTK warnings) |
| `bc` | `bc -l` (math library) |
| `ntop` | `bmon` network monitor |

### Editor Configuration

| File | Description |
|------|-------------|
| `.emacs` | Emacs config — wombat theme, line numbers, 120x40 window, `uniq-lines` function |
| `.emacs-windows` | Emacs config for Windows |

### Windows Configuration

| File | Description |
|------|-------------|
| `aliases.bat` | DOS aliases: `ls`, `cp`, `xcp`, `mv`, `clear`, `h`, `alias` |
| `netlogon.bat` | Network logon script |
| `run-bi.bat` | BI application launcher |
| `MJS - fix passwordless login.bat` | Passwordless login fix script |
| `hitman2-keys.reg` | Game-specific key bindings registry file |

### Windows Right-Click Menu (`right-click/`)

Registry files to enable or disable the Windows context menu:

- `enable_right_click_Allusers.reg` / `disable_right_click_Allusers.reg`
- `enable_right_click_Currentuser.reg` / `disable_right_click_Currentuser.reg`

### Utility Scripts

| File | Description |
|------|-------------|
| `restart-wifi.sh` | Restarts the `brcmfmac` WiFi driver on Linux |
| `start_portainer.sh` | Starts Docker Portainer container |
| `upgrade_portainer.txt` | Step-by-step commands for upgrading Portainer |

## Notes

- Shell scripts use Unix line endings (LF)
- Batch files use DOS line endings (CRLF)
- Registry files use UTF-16 encoding with BOM
