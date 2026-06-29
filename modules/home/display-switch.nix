{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.display-switch;

  iniText =
    ''
      usb_device = "${cfg.usbDevice}"
      on_usb_connect = "${cfg.onUsbConnect}"
    ''
    + lib.optionalString (cfg.onUsbDisconnect != null) ''
      on_usb_disconnect = "${cfg.onUsbDisconnect}"
    '';
in
{
  options.services.display-switch = {
    enable = lib.mkEnableOption "display-switch USB KVM monitor switching";

    package = lib.mkPackageOption pkgs "display-switch" { };

    usbDevice = lib.mkOption {
      type = lib.types.str;
      default = "046d:c53f";
      description = "USB vendor:product ID (hex) to watch for connect events.";
    };

    onUsbConnect = lib.mkOption {
      type = lib.types.str;
      example = "DisplayPort1";
      description = ''
        Monitor input to switch to when the USB device connects.
        Supported values include Hdmi1, Hdmi2, DisplayPort1, DisplayPort2, Dvi1, Dvi2, and Vga1.
      '';
    };

    onUsbDisconnect = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Hdmi1";
      description = ''
        Optional monitor input to switch to when the USB device disconnects.
        Leave unset when display-switch runs on both computers and only switches on connect.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."display-switch/display-switch.ini" = lib.mkIf pkgs.stdenv.isLinux {
      text = iniText;
    };

    home.file."Library/Preferences/display-switch.ini" = lib.mkIf pkgs.stdenv.isDarwin {
      text = iniText;
    };

    systemd.user.services.display-switch = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Switch monitor inputs when the USB KVM connects";
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/display_switch";
        Type = "simple";
        Restart = "always";
      };
      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.display-switch = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${cfg.package}/bin/display_switch" ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
