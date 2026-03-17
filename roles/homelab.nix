{ pkgs, ... }:
{
  home-manager.users.stevedv.home.packages = with pkgs; [
    colima
    docker-client
  ];

  home-manager.users.stevedv.home.shellAliases = {
    docker-start = "colima start";
    docker-stop = "colima stop";
  };
}
