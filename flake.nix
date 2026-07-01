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
      ...
    }:
    let
      username = "dima";
      darwinHostname = "Dmytros-MacBook-Pro";
      dimaPCHostname = "Dima-PC";
      darwinHomeDirectory = "/Users/${username}";
      nixosHomeDirectory = "/home/${username}";
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
      commonConfiguration = { pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          git
          curl
          wget
          vim
          nixfmt
          man
          fish
          tailscale
          nh
          unzip
          jq
        ];
        documentation.man.enable = true;

        programs.fish.enable = true;

        nix.settings.experimental-features = "nix-command flakes";

        fonts.packages = with pkgs; [
          nerd-fonts.meslo-lg
        ];

        services.tailscale = {
          enable = true;
        };
      };
      darwinConfiguration = { pkgs, ... }: {

        environment.systemPackages = with pkgs; [
          yabai
          skhd
        ];

        system.configurationRevision = self.rev or self.dirtyRev or null;

        system.stateVersion = 6;

        nixpkgs.hostPlatform = "aarch64-darwin";

        users.users.${username}.home = darwinHomeDirectory;

        services.yabai = {
          enable = true;
          config = {
            layout = "bsp";
          };
          extraConfig = ''
            yabai -m config external_bar all:$(spacebar -m config height):0
            yabai -m signal --add event=mission_control_exit action='echo "refresh" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=display_added action='echo "refresh" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=display_removed action='echo "refresh" | nc -U /tmp/yabai-indicator.socket'

            yabai -m signal --add event=window_created action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_destroyed action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_focused action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_moved action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_resized action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_minimized action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
            yabai -m signal --add event=window_deminimized action='echo "refresh windows" | nc -U /tmp/yabai-indicator.socket'
          '';
        };

        environment.variables = {
          NH_DARWIN_FLAKE = "${darwinHomeDirectory}/.config/nix";
        };
      };
      nixosConfiguration =
        { pkgs, ... }:
        import ./config/nixos.nix {
          inherit pkgs;
          inherit home-manager;
          inherit catppuccin;
          inherit username;
          hostname = dimaPCHostname;
          homeDirectory = nixosHomeDirectory;
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
      darwinConfigurations.${darwinHostname} = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit username;
          hostname = darwinHostname;
          homeDirectory = darwinHomeDirectory;
        };
        modules = [
          mac-app-util.darwinModules.default
          commonConfiguration
          darwinConfiguration
          (
            { pkgs, ... }:
            {
              nixpkgs.overlays = [
                (final: prev: {
                  display-switch = final.callPackage ./pkgs/display-switch.nix { };
                })
              ];
            }
          )
          (
            { pkgs, ... }:
            let
              yabai-indicator = pkgs.callPackage ./pkgs/yabai-indicator.nix { };
            in
            {
              system.primaryUser = username;

              system.defaults = {
                dock = {
                  autohide = true;
                  show-recents = false;
                  mru-spaces = false;
                  orientation = "right";
                  persistent-apps = [
                    {
                      app = "/Users/${username}/Applications/Home Manager Apps/Google Chrome.app";
                    }
                    {
                      app = "/Users/${username}/Applications/Home Manager Apps/AyuGram.app";
                    }
                    {
                      app = "/Users/${username}/Applications/Home Manager Apps/kitty.app";
                    }
                    {
                      app = "/Users/${username}/Applications/Home Manager Apps/ChatGPT.app";
                    }
                  ];
                };
                finder = {
                  AppleShowAllExtensions = true;
                  ShowPathbar = true;
                  ShowStatusBar = true;
                };
                NSGlobalDomain = {
                  ApplePressAndHoldEnabled = false;
                  KeyRepeat = 2;
                  InitialKeyRepeat = 15;
                  "com.apple.swipescrolldirection" = true;
                };
                ".GlobalPreferences" = {
                  "com.apple.mouse.scaling" = -1.0;
                };
                CustomUserPreferences = {
                  "com.apple.symbolicHotKeys" = {
                    AppleSymbolicHotkeys = {

                    };
                  };
                };
                controlcenter = {
                  BatteryShowPercentage = true;
                  Sound = true;
                };
              };
              system.keyboard = {
                enableKeyMapping = true;
                remapCapsLockToEscape = true;
              };
              launchd.user.agents = {
                yabai-indicator = {
                  serviceConfig = {
                    ProgramArguments = [
                      "/usr/bin/open"
                      "-a"
                      ''"${yabai-indicator}/Applications/Home Manager Apps/YabaiIndicator.app"''
                    ];
                    RunAtLoad = true;
                    KeepAlive = false;
                  };
                };
              };
            }
          )
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit username;
              hostname = darwinHostname;
              homeDirectory = darwinHomeDirectory;
              # L27h-4A USB-C reports as 0x31 via DDC, not DisplayPort1/2.
              displayConnection = "0x31";
            };

            home-manager.users.${username} = import ./modules/home/dima.nix;
          }
          (
            { pkgs, ... }:
            let
              yabai-indicator = pkgs.callPackage ./pkgs/yabai-indicator.nix { };
            in
            {
              # Mac-specific home-manager configs
              home-manager.users.${username} = { pkgs, ... }: {
                imports = [
                  catppuccin.homeModules.catppuccin
                ];
                home.packages = import ./modules/home/darwin-packages.nix { inherit pkgs; } ++ [ yabai-indicator ];
                programs.rectangle.enable = true;
                programs.git.settings.credential.helper = "osxkeychain";
                services.skhd = {
                  enable = true;
                  config = ''
                    cmd - return : open -n -a "/Users/${username}/Applications/Home Manager Apps/kitty.app"

                    cmd + shift - return : open -na "/Users/${username}/Applications/Home Manager Apps/Google Chrome.app" --args --new-window

                    cmd - 1 : yabai -m space --focus 1

                    cmd - 2 : yabai -m space --focus 2 || osascript ${./create_new_space.scrpt}

                    cmd - 3 : yabai -m space --focus 3 || osascript ${./create_new_space.scrpt}

                    cmd - 4 : yabai -m space --focus 4 || osascript ${./create_new_space.scrpt}

                    cmd + shift - f : yabai -m window --toggle float

                    cmd + shift - p : yabai -m window --toggle sticky

                    cmd - g : yabai -m window --toggle zoom-fullscreen

                    cmd - h : yabai -m window --focus west

                    cmd - j : yabai -m window --focus south

                    cmd - k : yabai -m window --focus north

                    cmd - l : yabai -m window --focus east

                    ctrl - right : yabai -m space --focus next

                    ctrl - left : yabai -m space --focus prev

                    :: move

                    cmd - m ; move

                    move < cmd - 1 : yabai -m window --space 1

                    move < cmd - 2 : yabai -m window --space 2

                    move < cmd - 3 : yabai -m window --space 3

                    move < cmd - 4 : yabai -m window --space 4

                    move < cmd - h : yabai -m window --warp west

                    move < cmd - j : yabai -m window --warp south

                    move < cmd - k : yabai -m window --warp north

                    move < cmd - l : yabai -m window --warp east

                    move < ctrl - right : yabai -m window --space next

                    move < ctrl - left : yabai -m window --space prev

                    move < escape ; default

                    move < cmd - m ; default
                  '';
                };
              };
            }
          )
        ];
      };

      nixosConfigurations.${dimaPCHostname} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit username;
        };
        modules = [
          commonConfiguration
          nixosConfiguration
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            programs.git.config.credential.helper = "libsecret";
            home-manager.extraSpecialArgs = {
              inherit username;
              hostname = dimaPCHostname;
              homeDirectory = nixosHomeDirectory;
              nmrs-gui = nmrs-gui.packages.x86_64-linux.default;
              # Physical DisplayPort on L27h-4A (verify with: ddcutil getvcp 0x60).
              displayConnection = "0x0f";
            };

            home-manager.users.${username} = {
              imports = [
                catppuccin.homeModules.catppuccin
                ./modules/home/dima.nix
                ./modules/home/nixos.nix
              ];
            };
          }

        ];
      };
    };
}
