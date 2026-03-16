{ pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.warn-dirty = false;

  environment.systemPath = [ "/opt/homebrew/bin" ];

  system.primaryUser = "stevedv";
  users.users.stevedv = {
    name = "stevedv";
    home = "/Users/stevedv";
  };

  fonts.packages = [
    (pkgs.runCommand "berkeley-mono-nerd-font" { } ''
      mkdir -p $out/share/fonts/truetype
      cp ${../fonts}/*.ttf $out/share/fonts/truetype/
    '')
    pkgs.nerd-fonts.jetbrains-mono
  ];

  programs.zsh.enable = true;
  programs.zsh.enableGlobalCompInit = false;

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
        AppleFirstWeekday = {
          gregorian = 2;
        };
      };
    };

    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
      minimize-to-application = true;
      persistent-apps = [ ];
      persistent-others = [ ];
      autohide-delay = 10.0;
      wvous-br-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Other";
      NewWindowTargetPath = "file:///Users/stevedv/Downloads";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
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
    taps = [
      "nikitabobko/tap"
    ];
    brews = [
      "cocoapods"
      "displayplacer"
    ];
    casks = [
      "nikitabobko/tap/aerospace"
      "android-studio"
      "1password"
      "codex"
      "ghostty"
      "obsidian"
      "zed"
      # "karabiner-elements"  # requires interactive sudo for pkg install
    ];
    masApps = {
      "Xcode" = 497799835;
    };
    onActivation.cleanup = "zap";
  };

  launchd.agents.home-manager-activate = {
    serviceConfig = {
      Label = "org.nix-community.home-manager.activate";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && /Users/stevedv/.local/state/home-manager/gcroots/current-home/activate --driver-version 1"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/home-manager-activate.log";
      StandardErrorPath = "/tmp/home-manager-activate.log";
    };
  };

  launchd.daemons.kanata = {
    serviceConfig = {
      Label = "org.kanata.daemon";
      ProgramArguments = [
        "/etc/profiles/per-user/stevedv/bin/kanata"
        "-c"
        "/Users/stevedv/.config/kanata/kanata.kbd"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
      StandardErrorPath = "/Library/Logs/Kanata/kanata.err.log";
    };
  };

  system.activationScripts.postActivation.text = ''
    mkdir -p /Library/Logs/Kanata

    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"'

    # Exclude ~/Git from Spotlight indexing
    if ! mdutil -s /Users/stevedv/Git 2>&1 | grep -q "Indexing disabled"; then
      touch /Users/stevedv/Git/.metadata_never_index
      mdutil -i off /Users/stevedv/Git &>/dev/null || true
    fi

    # Global npm packages (not available in nixpkgs)
    mkdir -p /Users/stevedv/.npm-global
    NPM_CONFIG_PREFIX=/Users/stevedv/.npm-global npm i -g @steipete/summarize 2>/dev/null || true
    chown -R stevedv:staff /Users/stevedv/.npm-global
  '';

  security.sudo.extraConfig = ''
    stevedv ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    stevedv ALL=(ALL) NOPASSWD: /nix/store/*
  '';

  system.stateVersion = 6;
}
