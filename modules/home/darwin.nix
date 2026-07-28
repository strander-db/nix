{
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
}
