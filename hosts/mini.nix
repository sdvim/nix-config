_: {
  system.keyboard.swapLeftCommandAndLeftAlt = true;

  # Wake-on-LAN
  networking.wakeOnLan.enable = true;

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
