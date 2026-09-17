{
  pkgs,
  nmrs-gui,
  ...
}:
{
  imports = [
    ./battlenet.nix
    ./aion.nix
  ];

  home.packages = with pkgs; [
    steam
    dunst
    networkmanagerapplet
    pavucontrol
    nmrs-gui
    ayugram-desktop
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    catppuccin-kvantum
    wl-clipboard
    wl-clipboard-x11
    playerctl
    xwayland-satellite
  ];

  catppuccin = {
    cursors = {
      enable = true;
    };
    gtk.icon.enable = true;
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "blue" ];
        size = "standard";
      };
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt.enable = true;
  qt.style.name = "kvantum";
  qt.qt5ctSettings = {
    Appearance = {
      icon_theme = "Catppuccin-Mocha";
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
  };

  services.dunst = {
    enable = true;
    settings = { };
  };

  programs.fuzzel.enable = true;

  # Terminal stays on kitty for NixOS/niri; Darwin uses Ghostty (AX-friendly).
  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
    enableGitIntegration = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "MesloLGM Nerd Font";
      size = 14;
    };
    settings = {
      shell = "${pkgs.fish}/bin/fish --login --interactive";
      enabled_layouts = "splits,stack";
    };
    keybindings = {
      "cmd+d" = "launch --location=split --cwd=current";
      "cmd+w" = "close_window";
      "ctrl+h" = "neighboring_window left";
      "ctrl+j" = "neighboring_window down";
      "ctrl+k" = "neighboring_window up";
      "ctrl+l" = "neighboring_window right";
      "cmd+c" = "copy_to_clipboard";
      "cmd+v" = "paste_from_clipboard";
      "cmd+\\" = "next_layout";
      "cmd+t" = "new_tab";
    };
  };

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-blue-cursors";
    size = 32;
  };
  home.sessionVariables = {
    GTK_THEME = "catppuccin-mocha-blue-standard";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  services.polkit-gnome.enable = true;
}
