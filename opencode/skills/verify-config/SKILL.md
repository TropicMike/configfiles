---
name: Verify OpenCode Config
description: Work out which OpenCode configuration is actually loaded and in effect, and which model every agent resolves to. Use this whenever the user asks whether their opencode.json or opencode.jsonc is being picked up, whether a project config is shadowing their global one, why a model or agent is not what they set, or wants to confirm settings after editing config. Triggers include "is my config working", "which config am I using", "did my model change take effect", "why is it still using the old model", "is this config loaded", and any config-reload or agent-model troubleshooting.
---

# Verify OpenCode Config

Reading the file you just edited tells you nothing about what OpenCode loaded.
Configuration is merged from built-in defaults, the global file, project files
in every ancestor directory, and a system directory — in a specific order. The
only reliable answer comes from asking the running service what it resolved.

This skill answers three questions:

1. Which config files were loaded, and in what precedence order?
2. What model does each agent actually resolve to right now?
3. Is some project config quietly shadowing the global settings?

## Run the bundled script

```sh
verify-config                 # report on the shared service's location
verify-config --dir .         # report on the current directory instead
```

If `~/.opencode/bin` is on PATH, `verify-config` works from anywhere. Windows has
no shim, so run the script directly there:

```bat
python "%USERPROFILE%\.config\opencode\skills\verify-config\scripts\verify_config.py"
```

**Understand the binding first.** `opencode api` talks to the shared background
service, and that service's location is fixed when it starts — it does not
follow your current directory. So the default mode reports on wherever the
service is anchored, which is usually the directory the user actually runs the
TUI from. To inspect any other directory, pass `--dir <path>`, which starts a
private standalone server bound to that path.

This distinction matters: answering "is my project config being used?" from the
wrong anchor produces a confident but wrong answer. If the script's `directory`
line is not the directory the user is asking about, rerun with `--dir`.

Flags:

| Flag | Effect |
| --- | --- |
| `--dir <path>` | Inspect that directory via a standalone server |
| `--json` | Raw documents and agents, for further processing |
| `--quiet` | Exit 1 if a project config shadows the global one, else 0 |
| `--help` | Usage |

## Reading the output

**Config documents** are listed lowest to highest precedence. The last
document that sets a key wins. `(built-in defaults)` carries no path; a
directory entry is where OpenCode looked for agents, skills, and commands, not
a config file.

Both a global and a project document appearing is normal — but if the project
one sets `model` or `agents`, it overrides the global value for that subtree.
That is the most common cause of "my config isn't being used".

**Agents** show the resolved `provider/model` each one will call. `inherits
session model` is expected for subagents that do not set a model; they follow
whatever the parent session is using.

**Recent config warnings** surfaces `level=WARN` and `level=ERROR` lines from
`~/.local/share/opencode/log/opencode.log`. A clean load produces none. A
warning here usually means a deprecated or malformed field was ignored.

## The gotcha that looks like a broken config

A session pins its agent and model when it is created. Editing config affects
**new sessions only**, so an existing session can legitimately keep an old
model forever. When a user says a change had no effect, check whether they
resumed an old session before touching the config:

```sh
opencode api get /api/session/<ses_id>/model
opencode api get /api/session/<ses_id>/agent
```

The fix is a new session, not a config change.

## If the answer is still unclear

Go one level deeper with the endpoints the script wraps:

```sh
opencode api get /api/config        # documents, each with its path
opencode api get /api/agent         # every agent and its model
opencode api get /api/agent/plan    # one agent, including its system prompt
opencode api get /api/model/default # effective default model for this directory
opencode api get /api/location      # which project OpenCode thinks you are in
```

Config is watched and reloaded automatically, so there is normally no reason to
restart. If a change genuinely has not landed, `/reload` in the TUI forces a
full reload of config, agents, commands, skills, MCP servers, and plugins.

Do not send the user to `Ctrl+P` → Open settings to verify this. That edits
`~/.config/opencode/cli.json`, which holds terminal preferences such as themes
and keybinds, not agent or model configuration.

## Notes

- Fields marked deprecated in the schema still load but may be ignored. V1's
  `small_model` has no V2 meaning beyond the hidden `title` agent; native V2
  configuration sets `agents.title.model` (plus `summary` and `compaction` for
  the other maintenance work).
- `request.body` values on an agent are preserved by V2 but not sent with model
  requests. Sampling settings belong on a model variant instead.
- `general` legitimately has no model: it inherits from the session.
