# Deprecated: former yabai / skhd / yabai-indicator bits from config/darwin.nix.
# Not imported by the flake.
{ pkgs, ... }:
let
  yabai-indicator = pkgs.callPackage ./yabai-indicator.nix { };
in
{
  environment.systemPackages = with pkgs; [ yabai skhd ];
  services.yabai = {
    enable = true;
    config.layout = "bsp";
    extraConfig = ''
      yabai -m config external_bar all:$(spacebar -m config height):0
      # … yabai-indicator refresh signals omitted; see git history
    '';
  };
  launchd.user.agents.yabai-indicator = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" ''"${yabai-indicator}/Applications/Home Manager Apps/YabaiIndicator.app"'' ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
  home-manager.extraSpecialArgs = { inherit yabai-indicator; };
}
