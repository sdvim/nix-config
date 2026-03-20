{
  pkgs,
  flakeDir,
  userName,
  ...
}:
let
  # Decimal key codes for HID modifier mapping (from IOHIDUsageTables.h)
  capsLock = 30064771129; # 0x700000039
  leftControl = 30064771296; # 0x7000000E0
  leftCommand = 30064771299; # 0x7000000E3
  leftOption = 30064771298; # 0x7000000E2

  mapping = src: dst:
    "<dict><key>HIDKeyboardModifierMappingSrc</key><integer>${toString src}</integer><key>HIDKeyboardModifierMappingDst</key><integer>${toString dst}</integer></dict>";

  # Coolermaster Novatouch TKL (VendorID 9494, ProductID 39)
  novaTouchDefaultsKey = "com.apple.keyboard.modifiermapping.9494-39-0";
  novaTouchHidMatching = ''{"VendorID":9494,"ProductID":39}'';
  novaTouchHidSet = builtins.toJSON {
    UserKeyMapping = [
      { HIDKeyboardModifierMappingSrc = capsLock; HIDKeyboardModifierMappingDst = leftControl; }
      { HIDKeyboardModifierMappingSrc = leftCommand; HIDKeyboardModifierMappingDst = leftOption; }
      { HIDKeyboardModifierMappingSrc = leftOption; HIDKeyboardModifierMappingDst = leftCommand; }
    ];
  };
in
{

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.warn-dirty = false;

  environment.systemPath = [ "/opt/homebrew/bin" ];

  system.primaryUser = userName;
  users.users.${userName} = {
    name = userName;
    home = "/Users/${userName}";
  };

  fonts.packages = [
    (pkgs.runCommand "berkeley-mono-font" { } ''
      mkdir -p $out/share/fonts/opentype
      cp ${../fonts}/*.otf $out/share/fonts/opentype/
    '')
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
      NewWindowTargetPath = "file:///Users/${userName}/Downloads";
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
    brews = [ ];
    casks = [
      "nikitabobko/tap/aerospace"
      "1password"
      "codex"
      "ghostty"
      "helium-browser"
      "homerow"
      "obsidian"
      "wispr-flow"

      # "karabiner-elements"  # requires interactive sudo for pkg install
    ];
    onActivation.cleanup = "zap";
  };

  launchd.agents.home-manager-activate = {
    serviceConfig = {
      Label = "org.nix-community.home-manager.activate";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && /Users/${userName}/.local/state/home-manager/gcroots/current-home/activate --driver-version 1"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/home-manager-activate.log";
      StandardErrorPath = "/tmp/home-manager-activate.log";
    };
  };

  # launchd.daemons.kanata = {
  #   serviceConfig = {
  #     Label = "org.kanata.daemon";
  #     ProgramArguments = [
  #       "/etc/profiles/per-user/${userName}/bin/kanata"
  #       "-c"
  #       "/Users/${userName}/.config/kanata/kanata.kbd"
  #     ];
  #     RunAtLoad = true;
  #     KeepAlive = true;
  #     StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
  #     StandardErrorPath = "/Library/Logs/Kanata/kanata.err.log";
  #   };
  # };

  system.activationScripts.postActivation.text = ''
    # Novatouch TKL: swap left cmd/alt + caps-to-ctrl (device-specific so
    # the internal keyboard is unaffected). defaults write persists across
    # reboots; hidutil applies immediately after the global keyboard config.
    sudo -u ${userName} defaults -currentHost write -g \
      ${novaTouchDefaultsKey} -array \
      '${mapping capsLock leftControl}' \
      '${mapping leftCommand leftOption}' \
      '${mapping leftOption leftCommand}'
    /usr/bin/hidutil property \
      --matching '${novaTouchHidMatching}' \
      --set '${novaTouchHidSet}' \
      > /dev/null

    # mkdir -p /Library/Logs/Kanata

    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"' 2>/dev/null || true

    # Exclude git directory from Spotlight indexing
    GIT_PARENT="${builtins.dirOf flakeDir}"
    if ! mdutil -s "$GIT_PARENT" 2>&1 | grep -q "Indexing disabled"; then
      touch "$GIT_PARENT/.metadata_never_index"
      mdutil -i off "$GIT_PARENT" &>/dev/null || true
    fi

    # Global npm packages (not available in nixpkgs)
    mkdir -p /Users/${userName}/.npm-global
    NPM_CONFIG_PREFIX=/Users/${userName}/.npm-global npm i -g @steipete/summarize 2>/dev/null || true
    chown -R ${userName}:staff /Users/${userName}/.npm-global
  '';

  security.sudo.extraConfig = ''
    ${userName} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    ${userName} ALL=(ALL) NOPASSWD: /nix/store/*
  '';

  system.stateVersion = 6;
}
