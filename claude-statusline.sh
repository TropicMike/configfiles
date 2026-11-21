#!/bin/bash
# Claude Code status line: user@host:dir in the same colors as the shell
# prompts (username red for root / green otherwise, hostname yellow, dir blue),
# followed by model | session cost | context-window usage when known.
# Claude Code pipes the session JSON on stdin. deploy.sh installs this as
# ~/.claude/statusline.sh, which claude-prompt.json points the statusLine at.

# Nothing to render without jq, and nothing worth rendering if the session
# payload is unusable: exit quietly instead of printing a prompt with no
# directory (and jq's parse errors on stderr).
command -v jq >/dev/null 2>&1 || exit 0

# One jq call extracts every field, joined by the ASCII unit separator (\x1f):
# unlike a tab, a non-whitespace IFS character keeps empty fields in place.
# Cost is blanked unless positive, so a fresh session doesn't show $0.00.
IFS=$'\x1f' read -r cwd model cost ctx < <(jq -r '[
    (.workspace.current_dir // ""),
    (.model.display_name // ""),
    (.cost.total_cost_usd // 0 | if . > 0 then tostring else "" end),
    (.context_window.used_percentage // "" | tostring)
  ] | join("\u001f")' 2>/dev/null)
# jq on Windows ends its output with CRLF, which read leaves on the last field.
ctx="${ctx%$'\r'}"
[ -n "$cwd" ] || exit 0

# Show ~ for the home directory, like \W / %1~ in the shell prompts.
if [ "$cwd" = "$HOME" ]; then
  dir="~"
else
  dir="${cwd##*/}"
  [ -n "$dir" ] || dir="$cwd"  # "/" has no last component
fi
if [ "$EUID" -eq 0 ]; then uc=31; else uc=32; fi

# This runs on every status line redraw, so avoid forks: printf -v instead of
# $(printf ...), and bash's $HOSTNAME (short form, like hostname -s) instead
# of running hostname. jq above is the only external process.
host="${HOSTNAME:-$(hostname)}"
printf -v out '\033[1;%sm%s\033[0m@\033[33m%s\033[0m:\033[1;34m%s\033[0m' \
  "$uc" "${USER:-$(id -un)}" "${host%%.*}" "$dir"
sep=$'\033[2m|\033[0m'
[ -n "$model" ] && out+=" $sep $model"
if [ -n "$cost" ]; then
  # shellcheck disable=SC2016  # literal $ for the currency sign
  printf -v cost '$%.2f' "$cost"
  out+=" $sep $cost"
fi
if [ -n "$ctx" ]; then
  printf -v ctx '%.0f' "$ctx"
  out+=" $sep Ctx:$ctx%"
fi
printf '%s' "$out"
