{
  self,
  pkgs,
  username,
  homeDirectory,
  ...
}:
let
  nehir = pkgs.callPackage ../pkgs/nehir.nix { };
  telegram-mac = pkgs.callPackage ../pkgs/telegram-mac.nix { };
  spotlight-exclusions = pkgs.writeShellApplication {
    name = "spotlight-exclusions";
    text = builtins.readFile ../modules/darwin/spotlight-exclusions.sh;
  };
in
{

  environment.systemPackages = with pkgs; [
    skhd
  ];

  # mac-app-util's SBCL trampoline sync OOMs mid-activation ("failed to allocate
  # ... at 0x300100000") and aborts before Home Manager runs — leaving skhd/hotkeys
  # stale after `nh darwin switch`. Apps still land in ~/Applications via HM copyApps.
  services.mac-app-util.enable = false;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = homeDirectory;

  environment.variables = {
    NH_DARWIN_FLAKE = "${homeDirectory}/.config/nix";
  };

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
          app = "/Users/${username}/Applications/Home Manager Apps/Telegram.app";
        }
        {
          app = "/Users/${username}/Applications/Ghostty.app";
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
    # Explicitly re-enable Spotlight (Cmd+Space). Removing a prior
    # `enabled = false` from nix-darwin does not restore the macOS default.
    # Remap Hide/Minimize off bare Cmd+H/M so skhd can own Cmd+HJKL for Nehir.
    CustomUserPreferences = {
      NSGlobalDomain = {
        NSUserKeyEquivalents = {
          Hide = "@~h";
          "Hide Others" = "@~^h";
          Minimize = "@~m";
        };
      };
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "64" = {
            enabled = true;
          };
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

  # Privacy-exclude non-app paths so Spotlight mainly indexes Applications
  # (including ~/Applications / Home Manager Apps).
  system.activationScripts.spotlightExclusions.text = ''
    echo "restricting Spotlight indexing to Applications..."
    ${spotlight-exclusions}/bin/spotlight-exclusions ${homeDirectory} || true
  '';

  launchd.user.agents = {
    nehir = {
      serviceConfig = {
        # `open <path.app>` (not `open -a`), and no embedded quotes in the argv.
        ProgramArguments = [
          "/usr/bin/open"
          "${nehir}/Applications/Nehir.app"
        ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };

  home-manager.extraSpecialArgs = {
    inherit nehir telegram-mac;
  };
  home-manager.users.${username}.imports = [
    ../modules/home/common.nix
    ../modules/home/darwin.nix
  ];
}
