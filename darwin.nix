{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "air";
  networking.computerName = "air";
  networking.localHostName = "air";

  system.primaryUser = "stevedv";
  users.users.stevedv = {
    name = "stevedv";
    home = "/Users/stevedv";
  };

  fonts.packages = [
    (pkgs.runCommand "berkeley-mono-nerd-font" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${./fonts}/*.ttf $out/share/fonts/truetype/
    '')
    pkgs.nerd-fonts.jetbrains-mono
  ];

  programs.zsh.enable = true;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {

    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      StandardHideDesktopIcons = true;
      StandardHideWidgets = true;
    };

    universalaccess.reduceMotion = true;

    menuExtraClock = {
      Show24Hour = false;
      ShowAMPM = true;
      ShowSeconds = true;
      ShowDayOfWeek = true;
      ShowDayOfMonth = false;
      ShowDate = 2;
      IsAnalog = false;
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleFirstWeekday = { gregorian = 2; };
      };
    };

    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
      minimize-to-application = true;
      persistent-apps = [];
      persistent-others = [];
      autohide-delay = 10.0;
      wvous-br-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };

    screencapture = {
      location = "~/Screenshots";
      type = "png";
      disable-shadow = true;
    };

    loginwindow.GuestEnabled = false;
  };

  homebrew = {
    enable = true;
    casks = [
      "obsidian"
      "ghostty"
      "bitwarden"
      "helium-browser"
      "claude-island"
    ];
    onActivation.cleanup = "zap";
  };

  system.activationScripts.postActivation.text = ''
    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"'
  '';

  security.sudo.extraConfig = ''
    stevedv ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    stevedv ALL=(ALL) NOPASSWD: /nix/store/*
  '';

  system.stateVersion = 6;
}
