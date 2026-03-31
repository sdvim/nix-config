{ userName, ... }:
{
  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ./scripts/claude-statusline.sh;
  };

  home.file.".claude/keybindings.json".text = builtins.toJSON {
    bindings = [
      {
        context = "Chat";
        bindings = {
          "ctrl+j" = "chat:newline";
        };
      }
    ];
  };

  # Runtime overrides go in ~/.claude/settings.local.json
  home.file.".claude/settings.json".text = builtins.toJSON {
    skipDangerousModePermissionPrompt = true;
    statusLine = {
      type = "command";
      command = "/Users/${userName}/.claude/statusline.sh";
    };
    hooks = {
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "PANE_ID=$(tmux display -p '#{pane_id}' 2>/dev/null); sed -i '' \"/^\${PANE_ID}$/d\" /tmp/tmux-claude-queue 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      PermissionRequest = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p @claude_waiting 1 2>/dev/null; PANE_ID=$(tmux display -p '#{pane_id}' 2>/dev/null); grep -qxF \"$PANE_ID\" /tmp/tmux-claude-queue 2>/dev/null || echo \"$PANE_ID\" >> /tmp/tmux-claude-queue; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      PostToolUse = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p -u @claude_waiting 2>/dev/null; PANE_ID=$(tmux display -p '#{pane_id}' 2>/dev/null); sed -i '' \"/^\${PANE_ID}$/d\" /tmp/tmux-claude-queue 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "tmux set-option -p -u @claude_waiting 2>/dev/null; PANE_ID=$(tmux display -p '#{pane_id}' 2>/dev/null); sed -i '' \"/^\${PANE_ID}$/d\" /tmp/tmux-claude-queue 2>/dev/null; tmux refresh-client -S 2>/dev/null; true";
            }
          ];
        }
      ];
    };
  };

  programs.zsh.initContent = ''
    # Clear stale @claude_waiting when back at shell prompt
    if [[ -n "$TMUX" ]]; then
      _clear_claude_waiting() { local p; p=$(tmux display -p '#{pane_id}' 2>/dev/null); tmux set-option -p -u @claude_waiting 2>/dev/null; grep -vxF "$p" /tmp/tmux-claude-queue > /tmp/tmux-claude-queue.tmp 2>/dev/null && mv /tmp/tmux-claude-queue.tmp /tmp/tmux-claude-queue || rm -f /tmp/tmux-claude-queue.tmp; tmux refresh-client -S 2>/dev/null; }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _clear_claude_waiting
    fi
  '';
}
