{ pkgs, userName, ... }:
{
  homebrew.brews = [
    "bazelisk"
    "cocoapods"
  ];

  homebrew.casks = [
    "android-studio"
  ];

  home-manager.users.${userName}.home.packages = with pkgs; [
    eas-cli
  ];
}
