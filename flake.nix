{
  description = "sdvim dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: uncomment after uninstalling brew claude-code
    # claude-code = {
    #   url = "github:sadjow/claude-code-nix";
    # };

  };

  outputs = { nixpkgs, nix-darwin, home-manager, ... }: {
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      modules = [
        { nixpkgs.hostPlatform = "aarch64-darwin"; }
        ./darwin.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "before-nix-darwin";
          home-manager.users.stevedv = import ./home.nix;
        }
      ];
    };
  };
}
