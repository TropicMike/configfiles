# OpenCode

OpenCode's global configuration and skills, deployed into OpenCode's config
directory by [`../deploy.sh`](../deploy.sh) (Linux/macOS/Git Bash) and
[`../deploy.bat`](../deploy.bat) (Windows).

The top-level [`README.md`](../README.md) carries the file inventory; this file
covers how the OpenCode pieces work, what the deploy scripts rewrite on the way
in, and how to run the `verify-config` skill on each platform.

## Contents

| Path | Deployed to | Deployed? |
|------|-------------|-----------|
| `opencode.jsonc` | `$XDG_CONFIG_HOME/opencode/opencode.jsonc` (default `~/.config/opencode`, `%USERPROFILE%\.config\opencode` on Windows) | Yes, rendered — see [The placeholder](#the-placeholder) |
| `opencode.dual-agent.jsonc` | — | **No.** Kept as a rollback target |
| `skills/verify-config/SKILL.md` | `<config dir>/skills/verify-config/SKILL.md` | Yes |
| `skills/verify-config/scripts/verify_config.py` | `<config dir>/skills/verify-config/scripts/verify_config.py`, plus a `verify-config` symlink in `~/.opencode/bin` when that directory exists | Yes |

Both deploy scripts install the OpenCode files **only when OpenCode is detected**
— `opencode` on `PATH`, or `~/.opencode/bin/opencode` (`.exe` on Windows). If it
is absent they print `SKIP opencode.jsonc (opencode not installed)` and move on
rather than creating a config directory OpenCode will not read.

Under `sudo`, `deploy.sh` deliberately ignores `XDG_CONFIG_HOME` and targets
root's `~/.config/opencode`, because a root shell's XDG variable would point at
the invoking user's directory.

## The placeholder

`opencode.jsonc` is a template. Its `instructions` entry is the literal

```json
"__AI_MEMORY_GLOB__"
```

Both deploy scripts replace that token at install time with
`<vault>/AI-memory/*.md`, absolute and `cygpath -m`-converted to `C:/…` when run
from Git Bash (OpenCode itself runs natively on Windows).

The vault is outside this repo, so it is found by probing, in order:

1. `~/Documents/MJS-Obsidian-Vault`
2. `~/Vaults/MJS-Obsidian-Vault`
3. `~/MJS-Obsidian-Vault`
4. `~` itself (a vault opened directly at the home directory)

Set `OBSIDIAN_VAULT` to override on any machine that keeps it elsewhere. If no
`AI-memory` folder is found, the scripts print a WARNING and install the config
anyway — deliberately, because OpenCode skips a glob that matches nothing
without reporting it, so silence would be indistinguishable from "no memories
yet".

Because the token is substituted on the way in, **edit the placeholder in the
repo, never the resolved path in the deployed copy** — the next deploy will
overwrite it.

## The three-model workflow

`opencode.jsonc` uses OpenCode's native V2 config shape: `agents`, `system`, and
`permissions` as ordered `{ action, resource, effect }` rules.

| Agent | Model | Role |
|-------|-------|------|
| `build` | `opencode-go/deepseek-v4.1-flash` | Implementation, refactoring, test/build fixes. Also the top-level `model`, so new sessions start here |
| `deepseek41-flash` | `opencode-go/deepseek-v4.1-flash` | The `default_agent`. Orchestrates routine work and dispatches `glm-advisor` when a decision needs judgement; no step cap |
| `plan` | `opencode-go/glm-5.3` | Planning. Its system prompt demands execution-ready output — exact paths, line ranges, verbatim before/after signatures, dependency and build-file changes, copy-pasteable verification — so `build` can implement without re-scanning the codebase. Language-agnostic: it infers the ecosystem from the files it reads |
| `explore` | `opencode-go/hy4-flash-free` | Repository mapping and symbol lookup at zero cost |
| `glm-advisor` | `opencode-go/glm-5.3` | Hidden subagent for second opinions, plan critique, and architecture tradeoffs; temperature 0.3, no step cap. Read-only: allows `read`, `glob`, `grep`, `webfetch`, `question`; denies `edit`, `shell`, `subagent`, `todowrite` |
| `title`, `summary`, `compaction` | `opencode-go/hy4-flash-free` | Hidden maintenance agents, all on the free model so background work costs nothing |

`deepseek41-flash` and `glm-advisor` previously had step caps (150 and 50).
They are now recorded as comments in `opencode.jsonc` so the values can be
restored by uncommenting a line.

### Why `title`/`summary`/`compaction`, not `small_model`

V1's top-level `small_model` is marked deprecated in the V2 schema and maps only
to the `title` agent. Setting the three hidden agents directly is the native V2
form and covers compaction as well. Keep `agents.title.model` if an older tool
expects `small_model`; do not add `small_model` alongside it.

`request.body` values on an agent are preserved by V2 but not sent with model
requests, so `glm-advisor`'s `temperature: 0.3` is documentation rather than
tuning. Sampling settings belong on a model variant.

## Rolling back

`opencode.dual-agent.jsonc` is the earlier two-agent config
(`deepseek41-flash` + `glm-advisor`), kept as a fallback. Nothing installs it.
To roll back:

```sh
cp opencode/opencode.dual-agent.jsonc ~/.config/opencode/opencode.jsonc
```

or copy it over the deployed file and fill in `__AI_MEMORY_GLOB__` by hand.

## The `verify-config` skill

Reading the config file you just edited says nothing about what OpenCode loaded.
Configuration merges built-in defaults, the global file, project files in every
ancestor directory, and a system directory — in that order. `verify-config` asks
the running service what it actually resolved.

It answers three questions:

1. Which config files were loaded, and in what precedence order?
2. What model does each agent resolve to right now?
3. Is a project config quietly shadowing the global one?

### Usage

```sh
verify-config                 # report on the shared service's location
verify-config --dir .         # report on the current directory instead
verify-config --json          # raw documents and agents
verify-config --quiet         # exit 1 if a project config shadows the global
verify-config --help          # usage
```

Without the `~/.opencode/bin` shim, run the script directly — this is the normal
case on Windows, and works on every platform:

```sh
python ~/.config/opencode/skills/verify-config/scripts/verify_config.py
```

On Windows:

```bat
python "%USERPROFILE%\.config\opencode\skills\verify-config\scripts\verify_config.py"
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Config loaded; no project override (or `--quiet` and none found) |
| `1` | `--quiet` only: a project config shadows the global one |
| `2` | The script could not query OpenCode (CLI missing, request failed, bad JSON) |

### Understanding the anchor

`opencode api` talks to the shared background service, and that service's
location is fixed when it starts — it does **not** follow your current
directory. The default mode therefore reports on wherever the service is
anchored, which is usually the directory the TUI was started from.

That distinction matters: answering "is my project config being used?" from the
wrong anchor produces a confident but wrong answer. If the `directory` line is
not the directory you care about, rerun with `--dir`.

`--dir` starts a private `--standalone` server bound to that path. A freshly
started standalone server has an empty agent registry, so in that mode the
script melds the loaded documents instead and labels the section
`Agents (derived from the loaded documents)`.

### Reading the output

- **Config documents** are listed lowest to highest precedence; the last
  document that sets a key wins. `(built-in defaults)` carries no path. A
  `directory` entry is where OpenCode scanned for agents, skills, and commands —
  not a config file. A non-global document is tagged `PROJECT OVERRIDE`.
- **Agents** show the resolved `provider/model`. `inherits session model` is
  expected for subagents that set none; they follow the parent session.
- **Recent config warnings** surfaces `level=WARN`/`level=ERROR` lines from the
  log that mention config, agent, or model. A clean load produces none.

### Cross-platform behaviour

The script runs unchanged on Linux, macOS, and Windows:

- **Locating the CLI.** `opencode` is resolved with `shutil.which()` rather than
  passed as a bare name. On Windows, npm installs `opencode` as a `.cmd` (and
  `.ps1`) shim in `%APPDATA%\npm`, and `CreateProcess` does not consult
  `PATHEXT` — so an unresolved `opencode` fails with
  `FileNotFoundError: [WinError 2]`. Resolution yields the real `.cmd` path,
  which runs directly. Candidates are `opencode`, then on Windows `.exe`,
  `.cmd`, `.bat`, `.ps1`; `~/.opencode/bin` is a last-resort fallback for a
  machine where the install directory is not on `PATH` yet.
- **PowerShell shims.** A `.ps1` shim cannot be executed directly, so it is run
  through `pwsh` (or `powershell`) with `-NoProfile -NonInteractive
  -ExecutionPolicy Bypass -File`.
- **XDG paths.** `XDG_CONFIG_HOME` and `XDG_DATA_HOME` are honoured when set,
  matching where the deploy scripts install and where OpenCode writes its log
  (`$XDG_DATA_HOME/opencode/log/opencode.log`).
- **Path comparison** for spotting the global document is normalised, so
  Windows case differences do not misfile it as a project override.
- **Output** is decoded as UTF-8 with replacement, so a stray byte in the log
  cannot crash a report.

### When the answer is still unclear

Go one level deeper with the endpoints the script wraps:

```sh
opencode api get /api/config        # documents, each with its path
opencode api get /api/agent         # every agent and its model
opencode api get /api/agent/plan    # one agent, including its system prompt
opencode api get /api/model/default # effective default model for this directory
opencode api get /api/location      # which project OpenCode thinks you are in
```

## Troubleshooting

**"My config change had no effect."** A session pins its agent and model when
it is created, so edits affect **new sessions only**. Check the existing session
before touching config:

```sh
opencode api get /api/session/<ses_id>/model
opencode api get /api/session/<ses_id>/agent
```

The fix is a new session, not a config change.

**Config genuinely has not reloaded.** Config is watched and reloaded
automatically, so a restart is normally unnecessary. `/reload` in the TUI forces
a full reload of config, agents, commands, skills, MCP servers, and plugins.

**Do not** verify via `Ctrl+P` → Open settings. That edits
`~/.config/opencode/cli.json`, which holds terminal preferences such as themes
and keybinds, not agent or model configuration.

**The deployed copy is stale.** `deploy.sh`/`deploy.bat` back up before
overwriting, so a changed file lands as `opencode.jsonc.bak` beside the new one.
`opencode.jsonc.bak` is inert — only `opencode.json` and `opencode.jsonc` are
loaded — but if you did not expect it, diff it before deleting.
