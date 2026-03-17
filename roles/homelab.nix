{ pkgs, userName, ... }:
{
  home-manager.users.${userName}.home.packages = with pkgs; [
    colima
    docker-client
  ];

  home-manager.users.${userName}.home.shellAliases = {
    docker-start = "colima start";
    docker-stop = "colima stop";
  };
}
