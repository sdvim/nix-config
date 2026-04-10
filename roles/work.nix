{ pkgs, userName, ... }:
{
  homebrew.brews = [
    "bazelisk"
    "cocoapods"
    "watchman"
  ];

  homebrew.casks = [
    "android-studio"
    "figma"
    "zed"
    "zulu@17"
  ];

  homebrew.masApps = {
    Velja = 1607635845;
  };

  home-manager.users.${userName} = {
    home.packages = with pkgs; [
      eas-cli
    ];
    home.sessionVariables = {
      ANDROID_HOME = "$HOME/Library/Android/sdk";
    };
    home.sessionPath = [
      "$HOME/Library/Android/sdk/platform-tools"
      "$HOME/Library/Android/sdk/emulator"
    ];
  };
}
