{ pkgs, ... }: {

  # Allow unfree packages (e.g. some fonts, proprietary tools)
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hostname
  networking.hostName = "air";
  networking.computerName = "air";
  networking.localHostName = "air";

  # Declare primary user so Home Manager can resolve homeDirectory
  # and nix-darwin knows who to apply per-user defaults to
  system.primaryUser = "stevedv";
  users.users.stevedv = {
    name = "stevedv";
    home = "/Users/stevedv";
  };

  # Fonts
  fonts.packages = [
    (pkgs.runCommand "berkeley-mono-nerd-font" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${./fonts}/*.ttf $out/share/fonts/truetype/
    '')
  ];

  # Use zsh as default shell (already the case on macOS)
  programs.zsh.enable = true;

  # ──────────────────────────────────────────────
  # Keyboard remapping
  # ──────────────────────────────────────────────
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # ──────────────────────────────────────────────
  # macOS System Preferences (via `defaults write`)
  # ──────────────────────────────────────────────

  system.defaults = {

    # Accessibility
    universalaccess.reduceMotion = true;

    # Menu bar clock
    menuExtraClock = {
      Show24Hour = false;
      ShowAMPM = true;
      ShowSeconds = true;
      ShowDayOfWeek = true;
      ShowDayOfMonth = false;
      ShowDate = 2;
      IsAnalog = false;
    };

    # Hide battery percentage from menu bar
    controlcenter.BatteryShowPercentage = false;

    # Hide WiFi and Spotlight from menu bar
    CustomUserPreferences = {
      "com.apple.controlcenter" = {
        "NSStatusItem Visible WiFi" = false;
      };
      "com.apple.Spotlight" = {
        "NSStatusItem Visible Item-0" = false;
      };
    };

    # Dock
    dock = {
      autohide = true;
      mru-spaces = false;           # Don't rearrange Spaces based on recent use
      show-recents = false;          # Hide recent apps in Dock
      tilesize = 48;
      minimize-to-application = true;
      persistent-apps = [];          # Clear all pinned apps
      persistent-others = [];        # Clear all pinned folders/stacks
      autohide-delay = 10.0;         # 10s delay before dock appears
      wvous-br-corner = 1;           # Disable bottom-right hot corner
    };

    # Finder
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv"; # Column view
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
    };

    # Keyboard
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;  # Enable key repeat instead of accents
      InitialKeyRepeat = 15;             # Shorter delay before repeat starts
      KeyRepeat = 2;                     # Fastest key repeat rate
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    # Trackpad
    trackpad = {
      Clicking = true;               # Tap to click
      TrackpadRightClick = true;     # Two-finger right click
    };

    # Screenshots
    screencapture = {
      location = "~/Screenshots";
      type = "png";
      disable-shadow = true;
    };

    # Login window
    loginwindow = {
      GuestEnabled = false;
    };
  };

  # Manage Homebrew declaratively (for GUI apps / casks)
  homebrew = {
    enable = true;

    # GUI apps (installed via `brew install --cask`)
    casks = [
      "obsidian"
      "ghostty"
      "bitwarden"
      "helium-browser"
    ];

    # Homebrew formulae that don't have good Nix equivalents
    brews = [
      # Add any brew-only formulae here
    ];

    # Remove anything not declared here on activation
    # Start with "none" until you've listed everything, then switch to "zap"
    onActivation.cleanup = "none";
  };

  # Set wallpaper to solid black
  system.activationScripts.postActivation.text = ''
    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"'
  '';

  # Allow passwordless sudo for nix-related commands (for darwin-rebuild)
  security.sudo.extraConfig = ''
    stevedv ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    stevedv ALL=(ALL) NOPASSWD: /nix/store/*
  '';

  # Required: system state version
  system.stateVersion = 6;
}
