_: {
  home.file.".claude/statusline.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)

      export CLAUDE_CONTEXT=$(printf '%s%%' "$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)")

      session_name=$(echo "$input" | jq -r '.session_name // empty')
      [[ -n "$session_name" ]] && export CLAUDE_SESSION="$session_name"

      STARSHIP_SHELL= starship prompt
    '';
  };

  # Runtime overrides go in ~/.claude/settings.local.json
  home.file.".claude/settings.json".text = builtins.toJSON {
    skipDangerousModePermissionPrompt = true;
    statusLine = {
      type = "command";
      command = "/Users/stevedv/.claude/statusline.sh";
    };
    hooks = {
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      PermissionRequest = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p -u @claude_waiting 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
    };
  };

  programs.zsh.initContent = ''
    # Clear stale @claude_waiting when back at shell prompt
    if [[ -n "$TMUX" ]]; then
      _clear_claude_waiting() { tmux set-option -p -u @claude_waiting 2>/dev/null; tmux refresh-client -S 2>/dev/null; }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _clear_claude_waiting
    fi
  '';
}
