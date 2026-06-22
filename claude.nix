_: {
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

  # ~/.claude/settings.json is intentionally not managed by Nix so Claude Code
  # can mutate it freely (themes, permissions, /config changes, etc.). Sync
  # across machines is manual for now — copy the file, or use a dotfile tool.

  programs.zsh.initContent = ''
    # Clear stale @claude_waiting when back at shell prompt
    if [[ -n "$TMUX" ]]; then
      _clear_claude_waiting() { local p; p=$(tmux display -p '#{pane_id}' 2>/dev/null); tmux set-option -p -u @claude_waiting 2>/dev/null; grep -vxF "$p" /tmp/tmux-claude-queue > /tmp/tmux-claude-queue.tmp 2>/dev/null && mv /tmp/tmux-claude-queue.tmp /tmp/tmux-claude-queue || rm -f /tmp/tmux-claude-queue.tmp; tmux refresh-client -S 2>/dev/null; }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _clear_claude_waiting
    fi
  '';
}
