{
  pkgs,
  username,
  catppuccin,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  home-manager.extraSpecialArgs = {
    inherit username;
    inherit catppuccin;
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.${username} = import ../modules/home/common.nix;
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
}
