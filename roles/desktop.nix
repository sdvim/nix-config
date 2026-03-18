{ lib, userName, ... }:
let
  terminalWorkspace = "~";
  renderTemplate = path:
    builtins.replaceStrings [ "__TERMINAL_WORKSPACE__" ] [ terminalWorkspace ] (builtins.readFile path);
in
{
  system.keyboard.swapLeftCommandAndLeftAlt = true;

  # Wake-on-LAN
  networking.wakeOnLan.enable = true;

  homebrew.brews = [
    "displayplacer"
  ];

  # Mini's display layout (other desktops override via lib.mkForce or host modules)
  launchd.agents.display-config = {
    serviceConfig = {
      Label = "org.displayplacer.config";
      ProgramArguments = [
        "/opt/homebrew/bin/displayplacer"
        "id:E1396AC8-A085-4A7F-B15A-DDE242FDA8A8 res:2560x1440 hz:60 color_depth:8 scaling:on origin:(0,0) degree:0"
        "id:48AFCCAF-DFDC-41D7-988C-E45717000DD1 res:3440x1440 hz:60 color_depth:8 scaling:off origin:(-440,-1440) degree:180"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/displayplacer.log";
      StandardErrorPath = "/tmp/displayplacer.log";
    };
  };

  home-manager.users.${userName}.home.file.".config/aerospace/aerospace.toml".text =
    renderTemplate ../config/aerospace/aerospace.toml
    + ''

      # Multi-monitor workspace split:
      # terminal prefers the external monitor when there are two displays,
      # otherwise it falls back to the main display
      [workspace-to-monitor-force-assignment]
      "${terminalWorkspace}" = ['secondary', 'main']
      "1" = 'main'
      "2" = 'main'
      "3" = 'main'
      "4" = 'secondary'
      "5" = 'secondary'
    '';

  # Enable remote access services (SSH, Screen Sharing, File Sharing)
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Remote Login (SSH)
    launchctl enable system/com.openssh.sshd
    launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true

    # Screen Sharing (VNC)
    launchctl enable system/com.apple.screensharing
    launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

    # File Sharing (SMB)
    launchctl enable system/com.apple.smbd
    launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
  '';
}
