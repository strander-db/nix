{
  description = "Nix system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    catppuccin.url = "github:catppuccin/nix";
    nmrs-gui.url = "github:networkmanager-rs/nmrs-gui";
    nmrs-gui.inputs.nixpkgs.follows = "nixpkgs";

    xremap-flake.url = "github:xremap/nix-flake";
    xremap-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      mac-app-util,
      catppuccin,
      nmrs-gui,
      xremap-flake,
      ...
    }:
    let
      username = "dima";
      mbProHostname = "Dmytros-MacBook-Pro";
      dimaPCHostname = "Dima-PC";
      darwinHomeDirectory = "/Users/${username}";
      nixosHomeDirectory = "/home/${username}";
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
      commonConfiguration =
        { pkgs, ... }:
        import ./config/common.nix {
          inherit pkgs;
          inherit username;
          inherit catppuccin;
        };
      darwinConfiguration =
        { pkgs, ... }:
        import ./config/darwin.nix {
          inherit self;
          inherit pkgs;
          inherit username;
          homeDirectory = darwinHomeDirectory;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          display-switch = pkgs.callPackage ./pkgs/display-switch.nix { };
        }
      );
      darwinConfigurations.${mbProHostname} = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit username;
          hostname = mbProHostname;
          homeDirectory = darwinHomeDirectory;
          inherit catppuccin;
        };
        modules = [
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          commonConfiguration
          darwinConfiguration
          {
            nixpkgs.overlays = [
              (final: prev: {
                display-switch = final.callPackage ./pkgs/display-switch.nix { };
              })
            ];
          }
          {
            home-manager.extraSpecialArgs = {
              hostname = mbProHostname;
              homeDirectory = darwinHomeDirectory;
              # L27h-4A USB-C reports as 0x31 via DDC, not DisplayPort1/2.
              displayConnection = "0x31";
            };
          }
        ];
      };

      nixosConfigurations.${dimaPCHostname} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit username;
          homeDirectory = nixosHomeDirectory;
          hostname = dimaPCHostname;
          inherit home-manager;
          inherit catppuccin;
        };
        modules = [
          ./config/common.nix
          ./config/nixos.nix
          ./config/Dima-PC-hardware.nix
          {
            nixpkgs.overlays = [
              (final: prev: {
                display-switch = final.callPackage ./pkgs/display-switch.nix { };
              })
            ];
          }
          ./modules/nixos/display-switch.nix
          {
            services.display-switch.enable = true;
          }
          {
            home-manager.extraSpecialArgs = {
              homeDirectory = nixosHomeDirectory;
              hostname = dimaPCHostname;
              nmrs-gui = nmrs-gui.packages.x86_64-linux.default;
              # Physical DisplayPort on L27h-4A (verify with: ddcutil getvcp 0x60).
              displayConnection = "0x0f";
            };
            home-manager.users.${username}.imports = [
              ./modules/home/common.nix
              ./modules/home/nixos.nix
              xremap-flake.homeManagerModules.default
            ];
          }

        ];
      };
    };
}
