_: {
  # Mini: focus Ghostty via AeroSpace (dedicated fullscreen monitor)
  home-manager.users.stevedv.home.file.".config/aerospace/aerospace.toml".text =
    builtins.readFile ../config/aerospace/aerospace.toml
    + ''

      # Focus Ghostty window (mini has a dedicated fullscreen monitor)
      ctrl-quote = 'exec-and-forget open -a Ghostty'
    '';

  system.keyboard.swapLeftCommandAndLeftAlt = true;

  # Wake-on-LAN
  networking.wakeOnLan.enable = true;

  # 34" ultrawide (inverted 180°) above 27" primary, horizontally centered
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

  # Enable remote access services (SSH, Screen Sharing, File Sharing)
  system.activationScripts.postActivation.text = ''
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
