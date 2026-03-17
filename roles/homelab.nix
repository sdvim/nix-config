{ pkgs, userName, ... }:
{
  home-manager.users.${userName} = {
    home.packages = with pkgs; [
      colima
      docker-client
    ];

    home.shellAliases = {
      docker-start = "colima start";
      docker-stop = "colima stop";
    };
  };
}
