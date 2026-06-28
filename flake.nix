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
      nixosHostname = "Dima-PC";
      darwinHomeDirectory = "/Users/${username}";
      nixosHomeDirectory = "/home/${username}";
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
      nixosConfiguration = { pkgs, ... }: {
        imports = [
          # Include the results of the hardware scan.
          ./hardware-configuration.nix
        ];

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "26.11";

        time.timeZone = "Europe/Kyiv";
        # Use the systemd-boot EFI boot loader.
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        # Use latest kernel.
        boot.kernelPackages = pkgs.linuxPackages_latest;

        networking.hostName = nixosHostname; # Define your hostname.

        # Configure network connections interactively with nmcli or nmtui.
        networking.networkmanager.enable = true;

        nixpkgs.config.allowUnfree = true;

        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber = {
            enable = true;
          };
        };

        users.users.${username} = {
          isNormalUser = true;
          home = nixosHomeDirectory;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
        };

        programs.hyprland = {
          enable = true;
          withUWSM = true;
        };
       

        programs.steam = {
          enable = true;
          extest.enable = true;
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };

        qt.platformTheme = "qt5ct";

        catppuccin = {
          enable = true;
          autoEnable = true;
        };
      };
    in
    {
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
                home.packages = import ./modules/home/darwin-packages.nix { inherit pkgs; } ++ [ yabai-indicator ];
                programs.rectangle.enable = true;
                programs.git.settings.credential.helper = "osxkeychain";
                services.skhd = {
                  enable = true;
                  config = ''
                    cmd - return : open -n -a "/Users/${username}/Applications/Home Manager Apps/kitty.app"

                    cmd + shift - return : open -a "/Users/${username}/Applications/Home Manager Apps/Google Chrome.app -- --args --new-window"

                    cmd - 1 : yabai -m space --focus 1

                    cmd - 2 : yabai -m space --focus 2 || osascript ${./create_new_space.scrpt}

                    cmd - 3 : yabai -m space --focus 3 || osascript ${./create_new_space.scrpt}

                    cmd - 4 : yabai -m space --focus 4 || osascript ${./create_new_space.scrpt}

                    cmd + shift - 1 : yabai -m window --space 1

                    cmd + shift - 2 : yabai -m window --space 2

                    cmd + shift - 3 : yabai -m window --space 3

                    cmd + shift - 4 : yabai -m window --space 4

                    cmd + shift - f : yabai -m window --toggle float

                    cmd + shift - p : yabai -m window --toggle sticky

                    cmd - g : yabai -m window --toggle zoom-fullscreen

                    cmd - h : yabai -m window --focus west

                    cmd - j : yabai -m window --focus south

                    cmd - k : yabai -m window --focus north

                    cmd - l : yabai -m window --focus east

                    cmd + shift - h : yabai -m window --warp west

                    cmd + shift - j : yabai -m window --warp south

                    cmd + shift - k : yabai -m window --warp north

                    cmd + shift - l : yabai -m window --warp east

                    ctrl + shift - right : yabai -m window --space next

                    ctrl + shift - left : yabai -m window --space prev

                    ctrl - right : yabai -m space --focus next

                    ctrl - left : yabai -m space --focus prev
                  '';
                };
              };
            }
          )
        ];
      };

      nixosConfigurations.${nixosHostname} = nixpkgs.lib.nixosSystem {
        modules = [
          commonConfiguration
          nixosConfiguration
          home-manager.nixosModules.default
          catppuccin.nixosModules.catppuccin
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit username;
              hostname = nixosHostname;
              homeDirectory = nixosHomeDirectory;
              nmrs-gui = nmrs-gui.packages.x86_64-linux.default;
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
