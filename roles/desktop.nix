{ lib, userName, ... }:
let
  terminalWorkspace = "~";
  renderTemplate =
    path:
    builtins.replaceStrings
      [ "__TERMINAL_WORKSPACE__" "__USER_HOME__" ]
      [ terminalWorkspace "/Users/${userName}" ]
      (builtins.readFile path);

in
{

  # Wake-on-LAN
  networking.wakeOnLan.enable = true;

  homebrew.brews = [
    "displayplacer"
  ];

  # Pro's display layout
  launchd.agents.display-config = {
    serviceConfig = {
      Label = "org.displayplacer.config";
      ProgramArguments = [
        "/opt/homebrew/bin/displayplacer"
        "id:1D1C74AB-4B77-468F-996C-B1692B6AB419 res:2560x1440 hz:60 color_depth:8 scaling:on origin:(0,0) degree:0"
        "id:E2BEC5A2-3C20-413F-AB1F-7795F470DCB5 res:3440x1440 hz:60 color_depth:8 scaling:off origin:(-440,-1440) degree:180"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/displayplacer.log";
      StandardErrorPath = "/tmp/displayplacer.log";
    };
  };

  home-manager.users.${userName}.home.file.".config/aerospace/aerospace.toml".text =
    renderTemplate ../config/aerospace/aerospace.toml;

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
