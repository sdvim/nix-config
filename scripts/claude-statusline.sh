#!/bin/bash
input=$(cat)

context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if (( context_pct >= 80 )); then
  export CLAUDE_CONTEXT="${context_pct}%"
fi

session_name=$(echo "$input" | jq -r '.session_name // empty')
[[ -n "$session_name" ]] && export CLAUDE_SESSION="$session_name"

STARSHIP_SHELL= starship prompt
