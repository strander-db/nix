{
  self,
  pkgs,
  username,
  homeDirectory,
  ...
}:
let
  yabai-indicator = pkgs.callPackage ../pkgs/yabai-indicator.nix { };
  spotlight-exclusions = pkgs.writeShellApplication {
    name = "spotlight-exclusions";
    text = builtins.readFile ../modules/darwin/spotlight-exclusions.sh;
  };
in
{

  environment.systemPackages = with pkgs; [
    yabai
    skhd
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = homeDirectory;

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
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Disable Cmd+Space for Spotlight Search
          "64" = {
            enabled = false;
          };
          # Disable Cmd+Alt+Space for Finder search window
          "65" = {
            enabled = false;
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
  # (including ~/Applications / Home Manager Apps). Breaks Vicinae file search.
  # Programmatic Privacy-list updates can be imperfect; reboot or toggle Privacy if needed.
  system.activationScripts.spotlightExclusions.text = ''
    echo "restricting Spotlight indexing to Applications..."
    ${spotlight-exclusions}/bin/spotlight-exclusions ${homeDirectory} || true
  '';

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
  home-manager.extraSpecialArgs = {
    inherit yabai-indicator;
  };
  home-manager.users.${username}.imports = [
    ../modules/home/common.nix
    ../modules/home/darwin.nix
  ];
}
