{ pkgs, userName, ... }:
{
  homebrew.brews = [
    "bazelisk"
    "cocoapods"
  ];

  homebrew.casks = [
    "android-studio"
    "visual-studio-code"
  ];

  homebrew.masApps = {
    Velja = 1607635845;
  };

  home-manager.users.${userName}.home.packages = with pkgs; [
    eas-cli
  ];
}
