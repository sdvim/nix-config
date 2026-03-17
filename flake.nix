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
      userName = "stevedv";
      flakeDir = "/Users/stevedv/Git/nix-config";
      mkHost =
        {
          hostName,
          computerName,
          roles ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit flakeDir userName; };
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/darwin.nix
            {
              networking.hostName = hostName;
              networking.computerName = computerName;
              networking.localHostName = hostName;
            }
          ]
          ++ roles
          ++ [
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-nix-darwin";
              home-manager.extraSpecialArgs = { inherit flakeDir userName; };
              home-manager.users.${userName} = import ./home.nix;
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
        roles = [ ./roles/laptop.nix ];
      };

      darwinConfigurations."mini" = mkHost {
        hostName = "mini";
        computerName = "Steve's Mac Mini";
        roles = [
          ./roles/desktop.nix
          ./roles/homelab.nix
        ];
      };

      darwinConfigurations."pro" = mkHost {
        hostName = "pro";
        computerName = "Steve's Macbook Pro";
        roles = [
          ./roles/desktop.nix
          ./roles/work.nix
        ];
      };
    };
}
