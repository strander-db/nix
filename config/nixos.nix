{
  pkgs,
  home-manager,
  catppuccin,
  username,
  hostname,
  homeDirectory,
  ...
}:
{
  imports = [
    home-manager.nixosModules.default
    catppuccin.nixosModules.catppuccin
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";

  environment.systemPackages = with pkgs; [
    hyprpolkitagent
  ];
  security.polkit.enable = true;

  time.timeZone = "Europe/Kyiv";
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = hostname; # Define your hostname.

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
    home = homeDirectory;
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
}
