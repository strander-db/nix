# Deprecated: former Hyprland system enablement from config/nixos.nix.
# Not imported by the flake.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ hyprpolkitagent libsecret ];
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
