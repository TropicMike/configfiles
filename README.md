# configfiles

[![CI](https://github.com/TropicMike/configfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/TropicMike/configfiles/actions/workflows/ci.yml)

Personal configuration files and dotfiles for Linux, macOS, and Windows environments. Managed in version control for backup and synchronization across systems. Deployment is manual.

## Usage

Run `./deploy.sh` to deploy the shared and OS-specific config files to your home directory.

To install the files for the **root** user, run the script with `sudo` (e.g. `sudo ./deploy.sh`) — it then deploys to root's home directory instead of yours.

## Files

### Shared (root directory)

| File | Description |
|------|-------------|
| `.aliases` | Shared aliases and shell functions (sourced by both bash and zsh); also checks in the background on every shell start for new upstream commits to this repo and prints a pull + deploy reminder (expects the clone at `~/Repos/configfiles`, falling back to `/c/Repos/configfiles` for Git Bash on Windows) |
| `.emacs` | Emacs config — wombat theme, cross-platform mono font, sh-mode for `.aliases`, 120x40 window, `uniq-lines` alias for `delete-duplicate-lines` |
| `claude-prompt.json` | Claude Code `statusLine` snippet — colored user@host:dir prompt (red for root, green otherwise) plus model, session cost, and context-window usage. `deploy.sh` merges it into `~/.claude/settings.json` (requires `jq`; other settings are kept) |
| `opencode/opencode.jsonc` | Global OpenCode config — see [OpenCode agents](#opencode-agents-opencodeopencodejsonc). Deployed to `$XDG_CONFIG_HOME/opencode` (default `~/.config/opencode`, `%USERPROFILE%\.config\opencode` on Windows) |

#### Aliases / Functions (`.aliases`)

| Alias/Function | Description |
|----------------|-------------|
| `e` | Open editor (macOS Emacs.app, standard emacs, or nano fallback) |
| `m` | `less` |
| `z` | `clear` |
| `md` | `mkdir` |
| `ls` | `ls --color` (Linux) / `ls -G` (macOS) |
| `lsd` | Long listing with color, sorted by time, paged |
| `rmbak` | Delete Emacs backup (`*~`) and autosave (`#*#`) files in current directory |
| `hex` | `hexdump -C` |
| `rsync` | `rsync -aSP` (archive, sparse, progress + partial) |
| `open` | `xdg-open` (Linux only) |
| `bc` | `bc -l` (math library) |
| `ntop` | `bmon` network monitor |
| `ipa` | Show IP addresses for all interfaces |

#### OpenCode agents (`opencode/opencode.jsonc`)

A fast primary worker plus a strategic advisor subagent, in OpenCode's native V2 config shape (`agents`, `system`, `permissions` as ordered `{ action, resource, effect }` rules, `request.body`):

| Agent | Model | Role |
|-------|-------|------|
| `glm-53-flash-worker` | `opencode-go/glm-5.3-flash` | Default primary agent for routine engineering work (editing, commands, orchestration); 30 steps |
| `glm-advisor` | `opencode-go/glm-5.3` | Hidden subagent for second opinions, plan critique, and architecture tradeoffs; 15 steps, temperature 0.3. Read-only: allows `read`, `glob`, `grep`, `webfetch`, `question`; denies `edit`, `shell`, `subagent`, `todowrite`. Its inline system prompt expects all context in the prompt and answers as CONCLUSION / REASONING / WATCH OUT |

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
| `setup.bat` | Bootstrap a new Windows machine — installs the baseline tools (Git, GitHub CLI, less) via winget; idempotent |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile — equivalents of the shared aliases (`e`, `m`, `z`, `hex`, `lsd`, `rmbak`, `ipa`), colored user@host:dir prompt (red for admin, green otherwise), and the upstream-commit check |
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
| `deploy.sh` | Deploys config files on Linux/macOS (and Git Bash on Windows, where it installs `.bashrc` too) — merges `claude-prompt.json` into `~/.claude/settings.json`, installs the OpenCode config — backs up existing files, skips unchanged. When run as root/sudo, deploys to root's home directory |
| `deploy.bat` | Deploys config files on Windows (`.emacs`, `aliases.bat`, the OpenCode config, the PowerShell profile for both Windows PowerShell 5.1 and pwsh 7 if installed, and `.aliases`/`.bashrc` for Git Bash if installed) — backs up existing files, skips unchanged |

## Notes

- Line endings and encodings are enforced via `.gitattributes`:
  - Shell scripts and dotfiles use Unix line endings (LF)
  - Batch files and PowerShell scripts use DOS line endings (CRLF)
  - Registry files use UTF-16 encoding with BOM
- CI (GitHub Actions) runs shellcheck, bash/zsh syntax and source checks, `deploy.sh` smoke tests on Linux and macOS (covering the Darwin-only branches), and PSScriptAnalyzer on every push
