#!/bin/bash
# Claude Code status line: user@host:dir in the same colors as the shell
# prompts (username red for root / green otherwise, hostname yellow, dir blue),
# followed by model | session cost | context-window usage when known.
# Claude Code pipes the session JSON on stdin. deploy.sh installs this as
# ~/.claude/statusline.sh, which claude-prompt.json points the statusLine at.

# One jq call extracts every field, joined by the ASCII unit separator (\x1f):
# unlike a tab, a non-whitespace IFS character keeps empty fields in place.
# Cost is blanked unless positive, so a fresh session doesn't show $0.00.
IFS=$'\x1f' read -r cwd model cost ctx < <(jq -r '[
    (.workspace.current_dir // ""),
    (.model.display_name // ""),
    (.cost.total_cost_usd // 0 | if . > 0 then tostring else "" end),
    (.context_window.used_percentage // "" | tostring)
  ] | join("\u001f")')

# Show ~ for the home directory, like \W / %1~ in the shell prompts.
if [ "$cwd" = "$HOME" ]; then
  dir="~"
else
  dir="${cwd##*/}"
  [ -n "$dir" ] || dir="$cwd"  # "/" has no last component
fi
if [ "$EUID" -eq 0 ]; then uc=31; else uc=32; fi

out=$(printf '\033[1;%sm%s\033[0m@\033[33m%s\033[0m:\033[1;34m%s\033[0m' \
  "$uc" "${USER:-$(id -un)}" "$(hostname -s)" "$dir")
sep=$'\033[2m|\033[0m'
[ -n "$model" ] && out+=" $sep $model"
# shellcheck disable=SC2016  # literal $ for the currency sign
[ -n "$cost" ] && out+=" $sep $(printf '$%.2f' "$cost")"
[ -n "$ctx" ] && out+=" $sep Ctx:$(printf '%.0f' "$ctx")%"
printf '%s' "$out"
