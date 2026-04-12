#!/bin/bash
input=$(cat)

context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if (( context_pct >= 80 )); then
  export CLAUDE_CONTEXT="${context_pct}%"
fi

ci_status=$(ci --statusline 2>/dev/null)
if [ -n "$ci_status" ]; then
  export CI_STATUS="$ci_status"
fi

STARSHIP_SHELL= starship prompt | sed 's/ ›$//'
