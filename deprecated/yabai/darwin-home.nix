{
  config,
  lib,
  pkgs,
  username,
  yabai-indicator,
  ...
}:
{
  home.packages = import ./darwin-packages.nix { inherit pkgs; } ++ [ yabai-indicator ];
  programs.rectangle.enable = true;
  programs.git.settings.credential.helper = "osxkeychain";
  services.skhd = {
    enable = true;
    config = ''
      cmd - space : /etc/profiles/per-user/${username}/bin/vicinae toggle

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

      move < 1 : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space 1; yabai -m window --focus "$id" ; default

      move < 2 : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space 2; yabai -m window --focus "$id" ; default

      move < 3 : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space 3; yabai -m window --focus "$id" ; default

      move < 4 : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space 4; yabai -m window --focus "$id" ; default

      move < h : yabai -m window --swap west ; default

      move < j : yabai -m window --swap south ; default

      move < k : yabai -m window --swap north ; default

      move < l : yabai -m window --swap east ; default

      move < right : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space next; yabai -m window --focus "$id" ; default

      move < left : id=$(yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r .id); yabai -m window --space prev; yabai -m window --focus "$id" ; default

      move < escape ; default

      move < cmd - m ; default
    '';
  };

  # HM packs clean.extraArgs as one argv on Darwin launchd; split so clap sees real flags.
  launchd.agents.nh-clean.config.ProgramArguments = lib.mkForce [
    (lib.getExe config.programs.nh.package)
    "clean"
    "user"
    "--keep-since"
    "30d"
    "--keep"
    "3"
    "--keep-one"
    "--optimise"
  ];
}
