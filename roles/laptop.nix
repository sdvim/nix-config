{ userName, ... }:
{
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;
  };

  # Laptop-specific Ghostty overrides
  home-manager.users.${userName}.home.file.".config/ghostty/config".text =
    builtins.readFile ../config/ghostty/config
    + ''

      # Start in fullscreen with no decorations
      fullscreen = true
      window-decoration = none
    '';
}
