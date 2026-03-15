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
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHost =
        {
          hostName,
          computerName,
          hostModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/darwin.nix
            {
              networking.hostName = hostName;
              networking.computerName = computerName;
              networking.localHostName = hostName;
            }
          ] ++ hostModules ++ [
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-nix-darwin";
              home-manager.users.stevedv = import ./home.nix;
            }
          ];
        };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt
          statix
          deadnix
        ];
      };

      darwinConfigurations."air" = mkHost {
        hostName = "air";
        computerName = "Steve's Macbook";
        hostModules = [ ./hosts/air.nix ];
      };

      darwinConfigurations."mini" = mkHost {
        hostName = "mini";
        computerName = "Steve's Mac Mini";
        hostModules = [ ./hosts/mini.nix ];
      };
    };
}
