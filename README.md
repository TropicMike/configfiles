# configfiles

Personal configuration files and dotfiles for Linux, macOS, and Windows environments. Managed in version control for backup and synchronization across systems. Deployment is manual.

## Usage

Run `./deploy.sh` to deploy the shared and OS-specific config files to your home directory.

To install the files for the **root** user, run the script with `sudo` (e.g. `sudo ./deploy.sh`) — it then deploys to root's home directory instead of yours.

## Files

### Shared (root directory)

| File | Description |
|------|-------------|
| `.aliases` | Shared aliases and shell functions (sourced by both bash and zsh) |
| `.emacs` | Emacs config — wombat theme, cross-platform mono font, sh-mode for `.aliases`, 120x40 window, `uniq-lines` function |

#### Aliases / Functions (`.aliases`)

| Alias/Function | Description |
|----------------|-------------|
| `e` | Open editor (emacs via snap, standard emacs, or nano fallback) |
| `m` | `less` |
| `z` | `clear` |
| `md` | `mkdir` |
| `ls` | `ls --color` (Linux) / `ls -G` (macOS) |
| `lsd` | Long listing with color, sorted by time, paged |
| `rmbak` | Delete `*~` and `#*` backup files in current directory |
| `hex` | `hexdump -C` |
| `open` | `xdg-open` (Linux only) |
| `vnc` | `vinagre` (suppresses GTK warnings) |
| `bc` | `bc -l` (math library) |
| `ntop` | `bmon` network monitor |
| `ipa` | Show IP addresses for all interfaces |

### Linux/

| File | Description |
|------|-------------|
| `.bashrc` | Bash initialization — sets PATH, sources `.aliases`, sets prompt |

### MacOS/

| File | Description |
|------|-------------|
| `.zshrc` | Zsh initialization — sets PATH, sources `.aliases`, sets prompt (red for root, green for user) |
| `macos-fix-home-end.sh` | Remaps Home/End keys to beginning/end of line via DefaultKeyBinding.dict |

### Windows/

| File | Description |
|------|-------------|
| `aliases.bat` | DOS aliases: `ls`, `cp`, `xcp`, `mv`, `clear`, `h`, `alias` |
| `netlogon.bat` | Network logon script |
| `run-bi.bat` | BI application launcher |
| `MJS - fix passwordless login.bat` | Passwordless login fix script |
| `hitman2-keys.reg` | Game-specific key bindings registry file |

### Windows/right-click/

Registry files to enable or disable the Windows context menu:

- `enable_right_click_Allusers.reg` / `disable_right_click_Allusers.reg`
- `enable_right_click_Currentuser.reg` / `disable_right_click_Currentuser.reg`

### Deploy Scripts

| File | Description |
|------|-------------|
| `deploy.sh` | Deploys config files on Linux/macOS — backs up existing files, skips unchanged. When run as root/sudo, deploys to root's home directory |
| `deploy.bat` | Deploys config files on Windows — backs up existing files, skips unchanged |

## Notes

- Line endings and encodings are enforced via `.gitattributes`:
  - Shell scripts and dotfiles use Unix line endings (LF)
  - Batch files use DOS line endings (CRLF)
  - Registry files use UTF-16 encoding with BOM
