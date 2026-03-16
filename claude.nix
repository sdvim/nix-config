_: {
  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ./scripts/claude-statusline.sh;
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
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux set-option -w pane-border-status bottom 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      PermissionRequest = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux set-option -w pane-border-status bottom 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; tmux set-option -w pane-border-status bottom 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p -u @claude_waiting 2>/dev/null; tmux set-option -w pane-border-status off 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
    };
  };

  programs.zsh.initContent = ''
    # Clear stale @claude_waiting when back at shell prompt
    if [[ -n "$TMUX" ]]; then
      _clear_claude_waiting() { tmux set-option -p -u @claude_waiting 2>/dev/null; tmux set-option -w pane-border-status off 2>/dev/null; tmux refresh-client -S 2>/dev/null; }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _clear_claude_waiting
    fi
  '';
}
