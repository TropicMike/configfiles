# configfiles

[![CI](https://github.com/TropicMike/configfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/TropicMike/configfiles/actions/workflows/ci.yml)

Personal configuration files and dotfiles for Linux, macOS, and Windows environments. Managed in version control for backup and synchronization across systems. Deployment is manual.

## Usage

Run `./deploy.sh` to deploy the shared and OS-specific config files to your home directory.

To install the files for the **root** user, run the script with `sudo` (e.g. `sudo ./deploy.sh`) — it then deploys to root's home directory instead of yours.

`./deploy.sh --dry-run` (`-n`) prints what would be installed, backed up, or merged without writing anything; `--help` lists the options.

Deploying also installs the OpenCode [`verify-config`](#opencode-skill--verify-config-opencodeskillsverify-config) skill and, where `~/.opencode/bin` exists, puts `verify-config` on your `PATH`. Run it after editing OpenCode config to see which files were actually loaded and what model each agent resolves to.

On Windows, run `deploy.bat` (and `Windows\setup.bat` first on a new machine).

The OpenCode config and skill are documented in full in [`opencode/README.md`](opencode/README.md) — the three-model workflow and its rationale, the `__AI_MEMORY_GLOB__` substitution and vault discovery, rollback to the two-agent config, and the `verify-config` skill's flags, exit codes, output, and per-platform behaviour.

## Files

### Shared (root directory)

| File | Description |
|------|-------------|
| `.aliases` | Shared aliases and shell functions (sourced by both bash and zsh); also checks in the background on every shell start for new upstream commits to this repo, retrying the remote fetch with backoff so it still works when the shell starts before the network is up (e.g. first Terminal after sleep/wake on macOS), and prints a pull + deploy reminder (expects the clone at `~/Repos/configfiles`, falling back to `/c/Repos/configfiles` for Git Bash on Windows) |
| `.emacs` | Emacs config — wombat theme, cross-platform mono font, sh-mode for `.aliases`, 120x40 window, `uniq-lines` alias for `delete-duplicate-lines` |
| `claude-prompt.json` | Claude Code `statusLine` snippet pointing at `~/.claude/statusline.sh`. `deploy.sh` merges it into `~/.claude/settings.json` (requires `jq`; other settings are kept) — only when Claude Code is installed |
| `claude-statusline.sh` | The status line itself — colored user@host:dir prompt matching the shell prompts (red for root, green otherwise; `~` at home) plus model, session cost (once non-zero), and context-window usage; requires `jq`, and renders nothing without it. `deploy.sh` installs it as `~/.claude/statusline.sh`. Not deployed by `deploy.bat` |
| `opencode/opencode.jsonc` | Global OpenCode config — the three-model workflow; see [OpenCode agents](#opencode-agents-opencodeopencodejsonc). Holds an `__AI_MEMORY_GLOB__` placeholder that the deploy scripts replace with this machine's Obsidian vault path. Deployed only if `opencode` is installed (on PATH or in `~/.opencode/bin`), to `$XDG_CONFIG_HOME/opencode` (default `~/.config/opencode`, `%USERPROFILE%\.config\opencode` on Windows) |
| `opencode/opencode.dual-agent.jsonc` | The earlier two-agent config (`deepseek41-flash` + `glm-advisor`), kept as a fallback. **Not deployed** — nothing installs it. To roll back, copy it over `opencode.jsonc` (or over the deployed copy, filling in the placeholder by hand) |
| `opencode/skills/verify-config/` | Global OpenCode skill `verify-config` (`SKILL.md` + `scripts/verify_config.py`). Reports which config files were actually loaded, in precedence order, and which model every agent resolves to — see [OpenCode skill](#opencode-skill--verify-config-opencodeskillsverify-config) and [`opencode/README.md`](opencode/README.md). Deployed to the same config directory's `skills/` folder. The script runs unchanged on Linux, macOS, and Windows — it resolves the `opencode` CLI through `PATH` (npm's Windows `.cmd` shim included) with a `~/.opencode/bin` fallback, and honours `XDG_CONFIG_HOME`/`XDG_DATA_HOME` |
| `opencode/README.md` | Documentation for the OpenCode section — how the config and skill deploy, the three-model workflow, the placeholder, rollback, and the skill's flags, exit codes, and platform notes. Not deployed |

#### Aliases / Functions (`.aliases`)

| Alias/Function | Description |
|----------------|-------------|
| `e` | Open editor (macOS Emacs.app, standard emacs, or nano fallback) |
| `m` | `less` |
| `z` | `clear` |
| `md` | `mkdir` |
| `ls` | `ls --color` (Linux) / `ls -G` (macOS) |
| `lsd` | Long listing with color, sorted by time, paged; takes an optional path |
| `rmbak` | Delete Emacs backup (`*~`) and autosave (`#*#`) files in current directory |
| `hex` | `hexdump -C` |
| `rsync` | `rsync -aSP` (archive, sparse, progress + partial) |
| `open` | `xdg-open` (Linux only) |
| `bc` | `bc -l` (math library) |
| `ntop` | `bmon` network monitor |
| `ipa` | Show IP addresses for all interfaces |

#### OpenCode agents (`opencode/opencode.jsonc`)

A three-model workflow in OpenCode's native V2 config shape (`agents`, `system`, `permissions` as ordered `{ action, resource, effect }` rules):

| Agent | Model | Role |
|-------|-------|------|
| `build` | `opencode-go/deepseek-v4.1-flash` | Implementation, refactoring, and test/build fixes. Also the top-level `model`, so every session starts here |
| `plan` | `opencode-go/glm-5.3` | Planning. Its system prompt demands execution-ready output — exact paths, line ranges, verbatim before/after signatures, dependency and build-file changes, and copy-pasteable verification commands — so `build` can implement without re-scanning the codebase. Language-agnostic: it infers the ecosystem from the files it reads rather than assuming JS/npm |
| `explore` | `opencode-go/hy4-flash-free` | Repository mapping and symbol lookup at zero cost |
| `deepseek41-flash` | `opencode-go/deepseek-v4.1-flash` | The `default_agent`. Orchestrates routine work and dispatches `glm-advisor` when a decision needs judgment; no step cap |
| `glm-advisor` | `opencode-go/glm-5.3` | Hidden subagent for second opinions, plan critique, and architecture tradeoffs; no step cap, temperature 0.3. Read-only: allows `read`, `glob`, `grep`, `webfetch`, `question`; denies `edit`, `shell`, `subagent`, `todowrite`. Its inline system prompt expects all context in the prompt and answers as CONCLUSION / REASONING / WATCH OUT |
| `title`, `summary`, `compaction` | `opencode-go/hy4-flash-free` | Hidden maintenance agents (title generation, summarising, compaction), all on the free model so background work costs nothing |

`deepseek41-flash` and `glm-advisor` previously had step caps (150 and 50). They are now recorded as comments in `opencode.jsonc` so the values can be restored by uncommenting a line.

**Why `title`/`summary`/`compaction` and not `small_model`.** V1's top-level `small_model` is marked deprecated in the V2 schema and maps only to the `title` agent. Setting the three hidden agents directly is the native V2 form and covers compaction as well. Keep `agents.title.model` if an older tool expects `small_model`; do not add `small_model` alongside it.

**Instructions — AI memory notes.** The `instructions` array loads every note in the Obsidian vault's `AI-memory/` folder into each session as background knowledge, so a fault that has already been diagnosed isn't diagnosed again. The vault lives outside this repo, so the entry is the placeholder `__AI_MEMORY_GLOB__`; `deploy.sh` and `deploy.bat` replace it at install time with `<vault>/AI-memory/*.md` (absolute, and `cygpath -m`-converted to `C:/…` when run from Git Bash, since OpenCode runs natively on Windows).

The vault is looked for at `~/Documents/MJS-Obsidian-Vault`, then `~/Vaults/MJS-Obsidian-Vault`, then `~/MJS-Obsidian-Vault`, then `~` itself (for a vault opened directly at the home directory); set `OBSIDIAN_VAULT` to override on any machine that keeps it elsewhere. If no `AI-memory` folder is found the scripts print a WARNING and still install the config — deliberately, because OpenCode skips a glob that matches nothing without reporting it, so a silent miss would look identical to "no memories yet".

#### OpenCode skill — `verify-config` (`opencode/skills/verify-config/`)

Reading the config file you edited says nothing about what OpenCode loaded: it merges built-in defaults, the global file, project files in every ancestor directory, and a system directory. This skill asks the running service instead.

```sh
verify-config            # the shared service's location
verify-config --dir .    # the current directory
verify-config --quiet    # exit 1 if a project config shadows the global one
verify-config --json     # raw documents and agents
```

It prints the loaded config documents in precedence order with any project override flagged, every agent's resolved `provider/model`, recent config warnings from `~/.local/share/opencode/log/opencode.log`, and a reminder that existing sessions keep the model they were created with.

`opencode api` binds to the shared background service, whose location is fixed when that service starts — it does not follow the caller's directory. That is why `--dir` exists: it starts a private `--standalone` server bound to the path given. A freshly started standalone server reports an empty agent registry, so in that mode the script derives each agent's model by merging the loaded documents and labels the section accordingly.

`deploy.sh` installs the skill and, when `~/.opencode/bin` exists, symlinks `verify-config` into it. `deploy.bat` installs the skill files but creates no shim, so on Windows run it directly as `python "%USERPROFILE%\.config\opencode\skills\verify-config\scripts\verify_config.py"`.

The script runs unchanged on Linux, macOS, and Windows. It resolves the `opencode` CLI through `PATH` rather than invoking a bare name: npm installs `opencode` on Windows as a `.cmd`/`.ps1` shim, and `CreateProcess` does not consult `PATHEXT`, so an unresolved name failed with `WinError 2`. A `.ps1` shim is run through `pwsh`/`powershell`, and `~/.opencode/bin` is the fallback when the install directory is not on `PATH` yet. `XDG_CONFIG_HOME` and `XDG_DATA_HOME` are honoured when set, matching where deployment installs and where OpenCode writes its log. Exit codes: `0` config loaded, `1` (`--quiet` only) a project config shadows the global one, `2` OpenCode could not be queried.

### Linux/

| File | Description |
|------|-------------|
| `.bashrc` | Bash initialization — sets PATH, large shared history (`histappend`, `ignoreboth`), sources `.aliases`, sets prompt |

### MacOS/

| File | Description |
|------|-------------|
| `.zshrc` | Zsh initialization — sets PATH (user dirs for non-root only), large history shared between terminals, sources `.aliases`, sets prompt (red for root, green for user) |
| `macos-fix-home-end.sh` | Remaps Home/End keys to beginning/end of line via DefaultKeyBinding.dict |

### Windows/

| File | Description |
|------|-------------|
| `setup.bat` | Bootstrap a new Windows machine — installs the baseline tools (Git, GitHub CLI, less) via winget (1.7+); idempotent |
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

### tests/

| File | Description |
|------|-------------|
| `verify_config_smoke.py` | Cross-platform smoke test for the `verify-config` skill's script, run by CI on Linux, macOS, and Windows. Installs a stub `opencode` CLI (a `.cmd` shim on Windows, the case that used to fail) and asserts the script resolves it, renders the report, parses `--json`, honours `--quiet` and the `0`/`1`/`2` exit codes, and fails with exit 2 and no traceback when no CLI exists. Needs no service, network, or login — run it directly with `python tests/verify_config_smoke.py` |

### Deploy Scripts

| File | Description |
|------|-------------|
| `deploy.sh` | Deploys config files on Linux/macOS (and Git Bash on Windows, where it installs `.bashrc` too) — installs the Claude status line script and merges `claude-prompt.json` into `~/.claude/settings.json` (both only when Claude Code is installed), installs the OpenCode config with its AI-memory glob filled in plus the `verify-config` skill (symlinking `verify-config` into `~/.opencode/bin` when present) — backs up existing files, skips unchanged, installs atomically, and exits 1 if anything failed. `--dry-run` previews. When run as root/sudo, deploys to root's home directory |
| `deploy.bat` | Deploys config files on Windows (`.emacs`, `aliases.bat`, the OpenCode config with its AI-memory glob filled in plus the `verify-config` skill files, the PowerShell profile for both Windows PowerShell 5.1 and pwsh 7 if installed, and `.aliases`/`.bashrc` for Git Bash if installed) — backs up existing files, skips unchanged, installs atomically, and exits 1 if anything failed. Does not set up the Claude status line or the `verify-config` command shim |

## Notes

- Line endings and encodings are enforced via `.gitattributes`:
  - Shell scripts and dotfiles use Unix line endings (LF)
  - Batch files and PowerShell scripts use DOS line endings (CRLF)
  - Registry files use UTF-16 encoding with BOM
- CI (GitHub Actions) runs shellcheck, bash/zsh syntax and source checks, JSON and `.reg` encoding checks, a status line render test, `deploy.sh` behavior tests (smoke tests on Linux and macOS covering the Darwin-only branches, dry run, symlinked and unwritable destinations, invalid snippet, sourcing from bash and zsh), PSScriptAnalyzer, and the `verify-config` smoke test on Linux, macOS, and Windows on every push
