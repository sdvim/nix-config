{ userName, ... }:
{
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;
  };

  # Quick terminal via Ghostty (ctrl+')
  home-manager.users.${userName}.home.file.".config/ghostty/config".text =
    builtins.readFile ../config/ghostty/config
    + ''

      # Start in fullscreen with no decorations
      fullscreen = true
      window-decoration = none

      # Quick terminal toggle (ctrl+')
      keybind = global:ctrl+apostrophe=toggle_quick_terminal

      # Spotlight picker toggle — send F12 escape sequence so tmux can match it
      keybind = shift+ctrl+apostrophe=text:\x1b[24~
      quick-terminal-position = center
      quick-terminal-size = 80%
      quick-terminal-autohide = true
      quick-terminal-animation-duration = 0
    '';
}
