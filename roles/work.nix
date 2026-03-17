{ pkgs, ... }:
{
  homebrew.brews = [
    "cocoapods"
  ];

  homebrew.casks = [
    "android-studio"
  ];

  home-manager.users.stevedv.home.packages = with pkgs; [
    eas-cli
  ];
}
