{
  config,
  lib,
  pkgs,
  homeDirectory,
  ...
}:
let
  battlenetPrefix = "${homeDirectory}/.local/share/battlenet-umu";
  battlenetExe = "${battlenetPrefix}/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe";

  battlenet-launch = pkgs.writeShellScriptBin "battlenet-launch" ''
    set -euo pipefail
    mkdir -p "${battlenetPrefix}"
    export STEAM_COMPAT_DATA_PATH="${battlenetPrefix}"
    export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
    export GAMEID="umu-0"
    exec ${lib.getExe pkgs.umu-launcher} "${battlenetExe}"
  '';

  wow-gamescope = pkgs.writeShellScriptBin "wow-gamescope" ''
    set -euo pipefail
    mode="''${1:-classic}"
    case "$mode" in
      classic)
        wow_exe="${battlenetPrefix}/pfx/drive_c/Program Files (x86)/World of Warcraft/_classic_era_/WowClassic.exe"
        ;;
      retail)
        wow_exe="${battlenetPrefix}/pfx/drive_c/Program Files (x86)/World of Warcraft/_retail_/Wow.exe"
        ;;
      *)
        echo "Usage: wow-gamescope [classic|retail]" >&2
        exit 1
        ;;
    esac

    # Make sure Battle.net is running so auth/session works.
    if ! ${pkgs.procps}/bin/pgrep -f "Battle.net Launcher.exe" >/dev/null 2>&1; then
      echo "Starting Battle.net..." >&2
      ${lib.getExe battlenet-launch} &
      ${pkgs.coreutils}/bin/sleep 8
    fi

    export STEAM_COMPAT_DATA_PATH="${battlenetPrefix}"
    export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
    export GAMEID="umu-wow"
    exec ${pkgs.gamescope}/bin/gamescope -W 2560 -H 1440 -r 100 -f -- \
      ${lib.getExe pkgs.umu-launcher} "$wow_exe"
  '';

in
{
  home.packages = [ battlenet-launch wow-gamescope pkgs.umu-launcher pkgs.gamescope ];

  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        "CTRL + SUPER + B"
        (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"name:battlenet\"}")
      ];
    }
  ];

  xdg.desktopEntries.battlenet = {
    name = "Battle.net";
    exec = "battlenet-launch";
    icon = "wine";
    categories = [ "Game" ];
    comment = "Battle.net launcher";
  };

  xdg.desktopEntries.wow-gamescope = {
    name = "WoW (Gamescope)";
    exec = "wow-gamescope";
    icon = "wine";
    categories = [ "Game" ];
    comment = "World of Warcraft via Gamescope (Battle.net must be running)";
  };
}
