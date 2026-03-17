{ pkgs, userName, ... }:
{
  homebrew.brews = [
    "cocoapods"
  ];

  homebrew.casks = [
    "android-studio"
  ];

  home-manager.users.${userName}.home.packages = with pkgs; [
    eas-cli
  ];
}
