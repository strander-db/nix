{
  lib,
  pkgs,
  homeDirectory,
  ...
}:
let
  aionDir = "${homeDirectory}/aion";
  aionPrefix = "${homeDirectory}/.local/share/aion-umu";
  empireSetup = "${aionDir}/AionEmpire-Setup.exe";
  # Common install locations after the Empire setup runs
  empireCandidates = [
    "${aionPrefix}/drive_c/Games/Aion Empire/launcher/launcher.exe"
    "${aionPrefix}/drive_c/Games/Aion Empire/launcher/Launcher.exe"
    "${aionPrefix}/drive_c/Program Files (x86)/AionEmpire/AionEmpire.exe"
    "${aionPrefix}/drive_c/Program Files/AionEmpire/AionEmpire.exe"
    "${aionPrefix}/drive_c/Program Files (x86)/Aion Empire/AionEmpire.exe"
    "${aionPrefix}/drive_c/users/steamuser/AppData/Local/AionEmpire/AionEmpire.exe"
  ];

  aionWinetricks = [
    "win10"
    "dotnet48"
    "vcrun2008"
    "vcrun2010"
    "vcrun2013"
    "vcrun2015"
    "d3dx9"
    "d3dcompiler_43"
    "physx"
    "corefonts"
    "gdiplus"
  ];

  aionEnv = ''
    mkdir -p "${aionPrefix}"
    export WINEPREFIX="${aionPrefix}"
    export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
    export GAMEID="umu-aion-empire"
    export PROTON_USE_WINED3D="''${PROTON_USE_WINED3D:-0}"
    # Prefer native MSVC CRT; leave ucrtbase as Wine builtin.
    export WINEDLLOVERRIDES="msvcp140,msvcp140_1,msvcp140_2,vcruntime140,vcruntime140_1,concrt140=n,b;''${WINEDLLOVERRIDES:-}"
  '';

  # Real Microsoft VC++ 2015–2022 DLLs (not Wine builtins).
  ensureNativeVcrun = ''
    redist64="${aionDir}/redist/vcrun2022/x64"
    redist86="${aionDir}/redist/vcrun2022/x86"
    sys64="${aionPrefix}/drive_c/windows/system32"
    sys86="${aionPrefix}/drive_c/windows/syswow64"
    bin64="${aionPrefix}/drive_c/Games/Aion Empire/classic/bin64"
    bin32="${aionPrefix}/drive_c/Games/Aion Empire/classic/bin32"
    if [[ -d "$redist64" ]]; then
      mkdir -p "$sys64"
      for d in "$redist64"/*.dll; do
        [[ -f "$d" ]] || continue
        cp -f "$d" "$sys64/$(basename "$d")"
        if [[ -d "$bin64" ]]; then
          cp -f "$d" "$bin64/$(basename "$d")"
        fi
      done
    fi
    if [[ -d "$redist86" ]]; then
      mkdir -p "$sys86"
      for d in "$redist86"/*.dll; do
        [[ -f "$d" ]] || continue
        cp -f "$d" "$sys86/$(basename "$d")"
        if [[ -d "$bin32" ]]; then
          cp -f "$d" "$bin32/$(basename "$d")"
        fi
      done
    fi
    # Same-size patched presence DLL (tiny stubs fail integrity/"corrupt")
    stub64="${aionDir}/redist/game_presence/game_presence-64.dll"
    stub32="${aionDir}/redist/game_presence/game_presence-32.dll"
    if [[ -f "$stub64" && -d "$bin64" ]]; then
      if [[ -f "$bin64/game_presence-64.dll" && ! -f "$bin64/game_presence-64.dll.real" ]]; then
        sz=$(stat -c%s "$bin64/game_presence-64.dll" || echo 0)
        if [[ "$sz" -gt 1000000 ]]; then
          cp -f "$bin64/game_presence-64.dll" "$bin64/game_presence-64.dll.real"
        fi
      fi
      cp -f "$stub64" "$bin64/game_presence-64.dll"
      cp -f "$stub64" "$sys64/game_presence-64.dll"
      mkdir -p "${aionPrefix}/drive_c/bin64"
      cp -f "$stub64" "${aionPrefix}/drive_c/bin64/game_presence-64.dll"
      cp -f "$stub64" "${aionPrefix}/drive_c/Games/Aion Empire/game_presence-64.dll"
      cp -f "$stub64" "${aionPrefix}/drive_c/Games/Aion Empire/classic/game_presence-64.dll" 2>/dev/null || true
      for alias in game_presence.dll game-presence.dll game-presence-64.dll Game_Presence.dll Game_presence-64.dll; do
        cp -f "$stub64" "$bin64/$alias"
      done
    fi
    if [[ -f "$stub32" && -d "$bin32" ]]; then
      cp -f "$stub32" "$bin32/game_presence-32.dll"
      for alias in game_presence.dll game-presence.dll game-presence-32.dll; do
        cp -f "$stub32" "$bin32/$alias"
      done
    fi
    if [[ -d "${aionPrefix}/drive_c/Games/Aion Empire/classic" ]]; then
      ln -sfn ../classic "${aionPrefix}/drive_c/Games/Aion Empire/launcher/classic"
      ln -sfn "Games/Aion Empire/classic/bin64" "${aionPrefix}/drive_c/bin64"
      ln -sfn "Games/Aion Empire/classic" "${aionPrefix}/drive_c/classic"
      apps="${aionPrefix}/drive_c/Games/Aion Empire/apps.ini"
      if [[ -f "$apps" ]] && ! grep -q 'root_directory=' "$apps"; then
        printf '%s\n' 'root_directory=C:\Games\Aion Empire\classic\' >> "$apps"
      fi
    fi
  '';

  resolveClient = ''
    client=""
    for c in ${lib.concatStringsSep " " (map (p: ''"${p}"'') empireCandidates)}; do
      if [[ -f "$c" ]]; then
        client="$c"
        break
      fi
    done
    if [[ -z "$client" ]]; then
      # Last resort: search for the Empire launcher exe
      client="$(find "${aionPrefix}/drive_c" \( -iname 'launcher.exe' -path '*/Aion Empire/*' -o -iname 'AionEmpire.exe' \) 2>/dev/null | head -1 || true)"
    fi
  '';

  aion-launch = pkgs.writeShellScriptBin "aion-launch" ''
    set -euo pipefail
    ${aionEnv}
    ${resolveClient}
    if [[ -z "$client" ]]; then
      echo "Aion Empire launcher is not installed yet." >&2
      echo "Run: aion-setup" >&2
      exit 1
    fi
    if [[ ! -f "${aionPrefix}/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/clr.dll" ]]; then
      echo "Prefix deps missing. Run: aion-setup" >&2
      exit 1
    fi
    ${ensureNativeVcrun}
    exec ${lib.getExe pkgs.umu-launcher} "$client" "$@"
  '';

  aion-setup = pkgs.writeShellScriptBin "aion-setup" ''
    set -euo pipefail
    ${aionEnv}
    umu=${lib.getExe pkgs.umu-launcher}
    log="${aionPrefix}/winetricks.log"
    touch "$log"

    if [[ ! -f "${empireSetup}" ]]; then
      echo "Missing ${empireSetup}" >&2
      exit 1
    fi

    if [[ ! -f "${aionPrefix}/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/clr.dll" ]] \
      || ! grep -qx 'dotnet48' "$log"; then
      echo "Clearing Proton fake .NET registry keys..."
      "$umu" reg delete "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4" /f || true
      "$umu" reg delete "HKLM\\Software\\Wow6432Node\\Microsoft\\NET Framework Setup\\NDP\\v4" /f || true
      "$umu" reg delete "HKLM\\Software\\Microsoft\\.NETFramework" /f || true
      "$umu" reg delete "HKLM\\Software\\Wow6432Node\\Microsoft\\.NETFramework" /f || true
    fi

    missing=()
    for verb in ${lib.concatStringsSep " " aionWinetricks}; do
      if ! grep -qx "$verb" "$log"; then
        missing+=("$verb")
      fi
    done

    if [[ ''${#missing[@]} -eq 0 ]]; then
      echo "Winetricks deps already present."
    else
      echo "Installing: ''${missing[*]}"
      "$umu" winetricks -q "''${missing[@]}"
    fi

    ${ensureNativeVcrun}
    echo "Installed native VC++ 2015-2022 runtimes for game_presence."

    ${resolveClient}
    if [[ -n "$client" ]]; then
      echo "Aion Empire already installed at: $client"
      echo "Launch with: aion-launch"
      exit 0
    fi

    echo "Running Aion Empire installer..."
    "$umu" "${empireSetup}" || true

    ${resolveClient}
    if [[ -n "$client" ]]; then
      echo "Installed: $client"
      echo "Next: aion-launch → sign in → download the client."
    else
      echo "Installer finished but launcher was not found." >&2
      find "${aionPrefix}/drive_c" -iname '*empire*' \( -iname '*.exe' -o -type d \) 2>/dev/null | head -20 >&2 || true
      exit 1
    fi
  '';
in
{
  home.packages = [
    aion-launch
    aion-setup
    pkgs.umu-launcher
  ];

  xdg.desktopEntries.aion = {
    name = "Aion Empire";
    exec = lib.getExe aion-launch;
    icon = "wine";
    categories = [ "Game" ];
    comment = "Aion Empire via Proton (XIGNCODE/GuardClient — may fail on Linux)";
  };
}
