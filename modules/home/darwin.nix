{
  config,
  lib,
  pkgs,
  nehir,
  telegram-mac,
  ...
}:
let
  nehirctl = "${nehir}/bin/nehirctl";
  hmApps = "${config.home.homeDirectory}/Applications/Home Manager Apps";
  ghosttyAppLink = "${config.home.homeDirectory}/Applications/Ghostty.app";
  ghosttyStoreApp = "${pkgs.ghostty-bin}/Applications/Ghostty.app";
  n = nehirctl;
  jq = "${pkgs.jq}/bin/jq";
  launchGhostty = pkgs.writeShellScript "launch-ghostty" ''
    set -euo pipefail
    log="${config.home.homeDirectory}/Library/Logs/skhd/launch-ghostty.log"
    mkdir -p "$(dirname "$log")"
    echo "$(date '+%Y-%m-%dT%H:%M:%S') launch-ghostty" >> "$log"
    /usr/bin/open -nb com.mitchellh.ghostty >>"$log" 2>&1 || {
      echo "open -b failed, trying app link" >> "$log"
      /usr/bin/open -na ${lib.escapeShellArg ghosttyAppLink} >>"$log" 2>&1
    }
  '';
  # Nehir has no move-column-to-monitor; resolve adjacent display and move there.
  moveColumnToMonitor = pkgs.writeShellScript "nehir-move-column-to-monitor" ''
    set -euo pipefail
    dir="''${1:?usage: left|right|up|down}"
    case "$dir" in left|right|up|down) ;; *) exit 1 ;; esac
    n=${lib.escapeShellArg nehirctl}
    target="$($n query displays --format json | ${jq} -r --arg dir "$dir" '
      .result.payload.displays as $all
      | ($all[] | select(.isCurrent == true)) as $cur
      | ($cur.frame.x + $cur.frame.width / 2) as $cx
      | ($cur.frame.y + $cur.frame.height / 2) as $cy
      | [
          $all[]
          | select(.id != $cur.id)
          | . as $d
          | ($d.frame.x + $d.frame.width / 2) as $dx
          | ($d.frame.y + $d.frame.height / 2) as $dy
          | ($dx - $cx) as $ox
          | ($dy - $cy) as $oy
          | if $dir == "left" and $ox < 0 and (($oy | fabs) <= ($ox | fabs)) then
              {number: $d.activeWorkspace.number, dist: ($ox | fabs)}
            elif $dir == "right" and $ox > 0 and (($oy | fabs) <= ($ox | fabs)) then
              {number: $d.activeWorkspace.number, dist: ($ox | fabs)}
            elif $dir == "up" and $oy < 0 and (($ox | fabs) <= ($oy | fabs)) then
              {number: $d.activeWorkspace.number, dist: ($oy | fabs)}
            elif $dir == "down" and $oy > 0 and (($ox | fabs) <= ($oy | fabs)) then
              {number: $d.activeWorkspace.number, dist: ($oy | fabs)}
            else empty end
        ]
      | sort_by(.dist)
      | .[0].number // empty
    ')"
    [ -n "$target" ] || exit 0
    $n command move-column-to-workspace "$target"
    $n command switch-workspace anywhere "$target"
  '';
in
{
  home.packages = import ./darwin-packages.nix { inherit pkgs; } ++ [
    nehir
    telegram-mac
  ];
  programs.rectangle.enable = false;
  programs.git.settings.credential.helper = "osxkeychain";

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    installBatSyntax = false;
    settings = {
      font-family = "MesloLGM Nerd Font";
      font-size = 14;
      command = "${pkgs.fish}/bin/fish --login --interactive";
      macos-option-as-alt = true;
      window-save-state = "never";
      keybind = [
        # Free niri-like Cmd chords for skhd (Ghostty defaults otherwise eat them).
        "super+enter=unbind"
        "super+f=unbind"
        "super+shift+f=unbind"
        "super+r=unbind"
        "super+shift+r=unbind"
        "super+o=unbind"
        "super+m=unbind"
        "super+comma=unbind"
        "super+period=unbind"
        "super+minus=unbind"
        "super+equal=unbind"
        "super+d=new_split:right"
        "super+w=close_surface"
        "ctrl+h=goto_split:left"
        "ctrl+j=goto_split:down"
        "ctrl+k=goto_split:up"
        "ctrl+l=goto_split:right"
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+backslash=toggle_split_zoom"
        "super+t=new_tab"
      ];
    };
  };

  home.activation.linkGhosttyApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Applications"
    ln -sfn ${lib.escapeShellArg ghosttyStoreApp} ${lib.escapeShellArg ghosttyAppLink}
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ${lib.escapeShellArg ghosttyAppLink} 2>/dev/null || true
  '';

  home.activation.reloadSkhd = lib.hm.dag.entryAfter [ "linkGhosttyApp" ] ''
    /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/org.nix-community.home.skhd" 2>/dev/null || true
  '';

  xdg.configFile."nehir/hotkeys.toml" = {
    source = ./nehir/hotkeys.toml;
    force = true;
  };
  xdg.configFile."nehir/settings.toml" = {
    source = ./nehir/settings.toml;
    force = true;
  };

  # Niri Mod ≈ Cmd. skhd event tap beats AppKit menu chords (Hide, Find, …).
  services.skhd = {
    enable = true;
    config = ''
      # --- launch ---
      cmd - return : ${launchGhostty}
      cmd + shift - return : open -na "Google Chrome" --args --new-window

      # --- focus (niri Mod+HJKL) ---
      cmd - h : ${n} command focus left
      cmd - j : ${n} command focus down
      cmd - k : ${n} command focus up
      cmd - l : ${n} command focus right
      cmd - home : ${n} command focus-column first
      cmd - end : ${n} command focus-column last

      # --- move window/column (niri Mod+Ctrl+HJKL) ---
      cmd + ctrl - h : ${n} command move-column left
      cmd + ctrl - l : ${n} command move-column right
      cmd + ctrl - j : ${n} command move-window-down
      cmd + ctrl - k : ${n} command move-window-up
      cmd + ctrl - home : ${n} command move-column-to-first
      cmd + ctrl - end : ${n} command move-column-to-last

      # --- move column to monitor (niri Mod+Shift+Ctrl+HJKL) ---
      cmd + shift + ctrl - h : ${moveColumnToMonitor} left
      cmd + shift + ctrl - l : ${moveColumnToMonitor} right
      cmd + shift + ctrl - k : ${moveColumnToMonitor} up
      cmd + shift + ctrl - j : ${moveColumnToMonitor} down

      # --- workspaces (niri Mod+N / Mod+Ctrl+N / Mod+U/I) ---
      cmd - 1 : ${n} command switch-workspace 1
      cmd - 2 : ${n} command switch-workspace 2
      cmd - 3 : ${n} command switch-workspace 3
      cmd - 4 : ${n} command switch-workspace 4
      cmd - 5 : ${n} command switch-workspace 5
      cmd - 6 : ${n} command switch-workspace 6
      cmd - 7 : ${n} command switch-workspace 7
      cmd - 8 : ${n} command switch-workspace 8
      cmd - 9 : ${n} command switch-workspace 9
      cmd + ctrl - 1 : ${n} command move-to-workspace 1
      cmd + ctrl - 2 : ${n} command move-to-workspace 2
      cmd + ctrl - 3 : ${n} command move-to-workspace 3
      cmd + ctrl - 4 : ${n} command move-to-workspace 4
      cmd + ctrl - 5 : ${n} command move-to-workspace 5
      cmd + ctrl - 6 : ${n} command move-to-workspace 6
      cmd + ctrl - 7 : ${n} command move-to-workspace 7
      cmd + ctrl - 8 : ${n} command move-to-workspace 8
      cmd + ctrl - 9 : ${n} command move-to-workspace 9
      cmd - u : ${n} command switch-workspace next
      cmd - i : ${n} command switch-workspace prev
      cmd + ctrl - u : ${n} command move-column-to-workspace down
      cmd + ctrl - i : ${n} command move-column-to-workspace up
      cmd - pagedown : ${n} command switch-workspace next
      cmd - pageup : ${n} command switch-workspace prev
      cmd + ctrl - pagedown : ${n} command move-column-to-workspace down
      cmd + ctrl - pageup : ${n} command move-column-to-workspace up

      # --- consume / expel (niri Mod+[ ] , .) ---
      # Carbon keycodes: [ = 0x21, ] = 0x1E, , = 0x2B, . = 0x2F
      cmd - 0x21 : ${n} command consume-or-expel-window-left
      cmd - 0x1E : ${n} command consume-or-expel-window-right
      cmd - 0x2B : ${n} command consume-window-into-column
      cmd - 0x2F : ${n} command expel-window-from-column

      # --- column / window sizing (niri Mod+F/R/-/= ) ---
      cmd - f : ${n} command toggle-column-full-width
      cmd + shift - f : ${n} command toggle-fullscreen
      cmd + ctrl - f : ${n} command expand-column-to-available-width
      cmd - r : ${n} command cycle-column-width forward
      cmd + shift - r : ${n} command cycle-column-width backward
      cmd + ctrl - r : ${n} command reset-window-height
      cmd + ctrl + shift - r : ${n} command cycle-window-height forward
      # Wrap ±% sizes: bare `-10%` confuses skhd's mode parser.
      cmd - 0x1B : /bin/bash -c '${n} command set-column-width -10%'
      cmd - 0x18 : /bin/bash -c '${n} command set-column-width +10%'
      cmd + shift - 0x1B : /bin/bash -c '${n} command set-window-height -10%'
      cmd + shift - 0x18 : /bin/bash -c '${n} command set-window-height +10%'

      # --- misc layout (niri Mod+O/V/M; Mod+W stays app Close) ---
      cmd - o : ${n} command toggle-overview
      cmd + shift - v : ${n} command toggle-focused-window-floating
      # niri Mod+M maximize-to-edges ≈ expand to free space
      cmd - m : ${n} command expand-column-to-available-width
    '';
  };

  launchd.agents.nh-clean.config.ProgramArguments = lib.mkForce [
    (lib.getExe config.programs.nh.package)
    "clean"
    "user"
    "--keep-since"
    "30d"
    "--keep"
    "3"
    "--keep-one"
    "--optimise"
  ];
}
