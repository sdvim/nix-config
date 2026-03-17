#!/bin/bash
input=$(cat)

context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if (( context_pct >= 80 )); then
  export CLAUDE_CONTEXT="${context_pct}%"
fi

STARSHIP_SHELL= starship prompt
