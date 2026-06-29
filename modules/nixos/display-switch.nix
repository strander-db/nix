# System prerequisites for display-switch on Linux (DDC/CI over i2c).
{
  config,
  lib,
  username,
  ...
}:

{
  options.services.display-switch.enable = lib.mkEnableOption "display-switch USB KVM monitor switching";

  config = lib.mkIf config.services.display-switch.enable {
  users.groups.i2c = { };

  users.users.${username}.extraGroups = [ "i2c" ];

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  };
}
