{
  config,
  lib,
  pkgs,
  nmrs-gui,
  username,
  homeDirectory,
  ...
}:
let

  waybarToggleClass = pkgs.writeShellScriptBin "waybar-toggle-class" ''
    set -euo pipefail

    class="$1"
    shift

    if ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -e --arg c "$class" '
      any(.[]; .class == $c or .initialClass == $c)' > /dev/null; then
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.window.close({ window = \"class:$class\" })"
    else
      "$@" &
    fi
  '';

  waybarToggleTitle = pkgs.writeShellScriptBin "waybar-toggle-title" ''
    set -euo pipefail

    title="$1"
    shift

    if ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -e --arg c "$title" '
      any(.[]; .title == $c or .initialTitle == $c)' > /dev/null; then
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.window.close({ name = \"title:^(\"$title\")$\" })"
    else
      "$@" &
    fi
  '';

  chromeClassFilter = [ "google-chrome" "Google-chrome" "chromium" ];

  chromeRemapList = [
    { from = "Super-X"; to = "C-x"; }
    { from = "Super-C"; to = "C-c"; }
    { from = "Super-V"; to = "C-v"; }
    { from = "Super-A"; to = "C-a"; }
    { from = "Super-Z"; to = "C-z"; }
    { from = "Super-Shift-Z"; to = "C-S-z"; }
    { from = "Super-T"; to = "C-t"; }
    { from = "Super-W"; to = "C-w"; }
    { from = "Super-Shift-T"; to = "C-S-t"; }
    { from = "Super-L"; to = "C-l"; }
    { from = "Super-F"; to = "C-f"; }
    { from = "Super-R"; to = "C-r"; }
    { from = "Super-D"; to = "C-d"; }
    { from = "Super-N"; to = "C-n"; }
    { from = "Super-Shift-N"; to = "C-S-n"; }
    { from = "Alt-Left"; to = "C-Left"; }
    { from = "Alt-Right"; to = "C-Right"; }
    { from = "Alt-Shift-Left"; to = "C-S-Left"; }
    { from = "Alt-Shift-Right"; to = "C-S-Right"; }
    { from = "Super-Left"; to = "Home"; }
    { from = "Super-Right"; to = "End"; }
    { from = "Super-Shift-Left"; to = "S-Home"; }
    { from = "Super-Shift-Right"; to = "S-End"; }
  ];

  workspaceSwitchRemap = {
    "Ctrl-Left" = "Super-Ctrl-Left";
    "Ctrl-Right" = "Super-Ctrl-Right";
  };

  normalXremapConfig = {
    keymap = [
      {
        name = "Workspace switching";
        remap = workspaceSwitchRemap;
      }
      {
        name = "Chrome mac-style shortcuts";
        application.only = chromeClassFilter;
        remap = lib.listToAttrs (
          map (r: {
            name = r.from;
            value = r.to;
          }) chromeRemapList
        );
      }
    ];
  };

  fullscreenXremapConfig = {
    modmap = [
      {
        name = "Swap Super/Alt in fullscreen workspace";
        remap = {
          KEY_LEFTMETA = "KEY_LEFTALT";
          KEY_LEFTALT = "KEY_LEFTMETA";
          KEY_RIGHTMETA = "KEY_RIGHTALT";
          KEY_RIGHTALT = "KEY_RIGHTMETA";
        };
      }
    ];
    keymap = [
      {
        name = "Passthrough Hyprland fullscreen exit shortcut";
        remap = {
          "C-Alt-F" = "C-Super-F";
        };
      }
      {
        name = "Chrome mac-style shortcuts";
        application.only = chromeClassFilter;
        remap = lib.listToAttrs (
          map (r: {
            name = r.from;
            value = r.to;
          }) chromeRemapList
        );
      }
    ];
  };

in
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
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    catppuccin-kvantum
    waybarToggleTitle
    waybarToggleClass
    hyprshutdown
    wl-clipboard
    wl-clipboard-x11
    playerctl
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
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.systemd.variables = [
    "DISPLAY"
    "HYPRLAND_INSTANCE_SIGNATURE"
    "WAYLAND_DISPLAY"
    "XDG_CURRENT_DESKTOP"
    "XDG_SESSION_TYPE"
    "XCURSOR_THEME"
    "XCURSOR_SIZE"
    "HYPRCURSOR_THEME"
    "HYPRCURSOR_SIZE"
  ];
  wayland.windowManager.hyprland.settings = {
    config = {
      misc = {
        vrr = 2;
      };
      input = {
        follow_mouse = 2;
        kb_layout = "us,ua";
        kb_options = "grp:ctrl_space_toggle,caps:swapescape";
        repeat_rate = 50;
        repeat_delay = 250;
      };
      general = {
        gaps_in = 3;
        gaps_out = 10;
        border_size = 2;
        col = {
          active_border = lib.generators.mkLuaInline ''
            { colors = { colors.accent, colors.surface1 }, angle = 45 }
          '';
          inactive_border = lib.generators.mkLuaInline "colors.surface0";
        };
        layout = "dwindle";
      };
      decoration = {
        rounding = 10;
        rounding_power = 2;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = lib.generators.mkLuaInline "'0xee' .. colors.crustAlpha .. 'ee'";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        animate_manual_resizes = true;
        focus_on_activate = true;
      };

      group = {
        groupbar = {
          font_size = 12;
          gradients = true;
        };
      };

      xwayland = {
        force_zero_scaling = true;
      };

    };
    on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd("${pkgs.coreutils}/bin/env QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 ${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy")
            hl.exec_cmd("battlenet-launch", { workspace = "name:battlenet" })
            hl.exec_cmd("steam", { workspace = "name:steam" })
          end
        '')
      ];
    };
    bind = [
      {
        _args = [
          "SUPER + RETURN"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"kitty\")")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + RETURN"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"google-chrome\")")
        ];
      }
      {
        _args = [
          "CTRL + SUPER + F"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"name:fullscreen\"}")
        ];
      }
      {
        _args = [
          "CTRL + SUPER + S"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"name:steam\"}")
        ];
      }
      {
        _args = [
          "SUPER + Q"
          (lib.generators.mkLuaInline "hl.dsp.window.close()")
        ];
      }
      {
        _args = [
          "SUPER + SPACE"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"vicinae toggle\")")
        ];
      }
      {
        _args = [
          "SUPER + 1"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = 1}")
        ];
      }
      {
        _args = [
          "SUPER + 2"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = 2}")
        ];
      }
      {
        _args = [
          "SUPER + 3"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = 3}")
        ];
      }
      {
        _args = [
          "SUPER + 4"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = 4}")
        ];
      }
      {
        _args = [
          "SUPER + M"
          (lib.generators.mkLuaInline "hl.dsp.submap(\"move\")")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + F"
          (lib.generators.mkLuaInline "hl.dsp.window.float{action = \"toggle\"}")
        ];
      }
      {
        _args = [
          "SUPER + G"
          (lib.generators.mkLuaInline "hl.dsp.window.fullscreen{mode = \"maximized\", action = \"toggle\"}")
        ];
      }
      {
        _args = [
          "SUPER + h"
          (lib.generators.mkLuaInline "hl.dsp.focus{direction = \"l\"}")
        ];
      }
      {
        _args = [
          "SUPER + j"
          (lib.generators.mkLuaInline "hl.dsp.focus{direction = \"d\"}")
        ];
      }
      {
        _args = [
          "SUPER + k"
          (lib.generators.mkLuaInline "hl.dsp.focus{direction = \"u\"}")
        ];
      }
      {
        _args = [
          "SUPER + l"
          (lib.generators.mkLuaInline "hl.dsp.focus{direction = \"r\"}")
        ];
      }
      {
        _args = [
          "SUPER + CTRL + RIGHT"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"e+1\", on_current_monitor = true}")
        ];
      }
      {
        _args = [
          "SUPER + CTRL + LEFT"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"e-1\", on_current_monitor = true}")
        ];
      }
    ];
  };
  wayland.windowManager.hyprland.submaps.move = {
    settings.bind = [
      {
        _args = [
          "SUPER + 1"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 1, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + 2"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 2, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + 3"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 3, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + 4"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 4, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + h"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"l\"}")
        ];
      }
      {
        _args = [
          "SUPER + j"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"d\"}")
        ];
      }
      {
        _args = [
          "SUPER + k"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"u\"}")
        ];
      }
      {
        _args = [
          "SUPER + l"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"r\"}")
        ];
      }
      {
        _args = [
          "SUPER + CTRL + RIGHT"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = \"e+1\", follow = true, on_current_monitor = true}")
        ];
      }
      {
        _args = [
          "SUPER + CTRL + LEFT"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = \"e-1\", follow = true, on_current_monitor = true}")
        ];
      }
      {
        _args = [
          "ESCAPE"
          (lib.generators.mkLuaInline "hl.dsp.submap(\"reset\")")
        ];
      }
      {
        _args = [
          "SUPER + M"
          (lib.generators.mkLuaInline "hl.dsp.submap(\"reset\")")
        ];
      }
    ];
  };
  wayland.windowManager.hyprland.extraLuaFiles = {
    monitors = {
      autoLoad = true;
      content = ''
        hl.monitor({
          output = "DP-1",
          mode = "2560x1440@99.95",
          position = "0x0",
          scale = 1,
        })
      '';
    };
    fullscreen_workspace = {
      autoLoad = true;
      content = ''
        local FULLSCREEN_WS = "fullscreen"
        local FULLSCREEN_WS_SEL = "name:fullscreen"
        local prev_ws = {}
        local fullscreen_windows = {}

        local xremap_dir = os.getenv("XDG_CONFIG_HOME")
        if not xremap_dir then
          xremap_dir = (os.getenv("HOME") or "") .. "/.config"
        end
        xremap_dir = xremap_dir .. "/xremap"

        local function set_xremap_fullscreen(enabled)
          local target = enabled and "fullscreen.yaml" or "normal.yaml"
          os.execute(string.format("cp -f %q/%q %q/active.yaml", xremap_dir, target, xremap_dir))
        end

        local function is_fullscreen_ws(name)
          return name == FULLSCREEN_WS
        end

        local function is_client_fullscreen(w)
          -- State 2 = fullscreen, 3 = maximize+fullscreen. State 1 (maximized) is SUPER+G — leave it alone.
          return w.fullscreen_client >= 2
        end

        local function count_fullscreen_windows()
          local n = 0
          for _ in pairs(fullscreen_windows) do
            n = n + 1
          end
          return n
        end

        local function update_fullscreen_mode()
          if count_fullscreen_windows() > 0 then
            hl.dispatch(hl.dsp.submap("fullscreen"))
            set_xremap_fullscreen(true)
          else
            hl.dispatch(hl.dsp.submap("reset"))
            set_xremap_fullscreen(false)
          end
        end

        local function move_to_fullscreen_ws(w)
          if not w.workspace or is_fullscreen_ws(w.workspace.name) then
            return
          end
          prev_ws[w.address] = w.workspace.name
          hl.dispatch(hl.dsp.window.move({
            window = "address:" .. w.address,
            workspace = FULLSCREEN_WS_SEL,
            follow = true,
          }))
        end

        local function restore_from_fullscreen_ws(w)
          local dest = prev_ws[w.address]
          if not dest then
            return
          end
          prev_ws[w.address] = nil
          local ws_sel = tonumber(dest) and dest or ("name:" .. dest)
          hl.dispatch(hl.dsp.window.move({
            window = "address:" .. w.address,
            workspace = ws_sel,
            follow = false,
          }))
        end

        local function handle_fullscreen(w)
          local was_fullscreen = fullscreen_windows[w.address]
          local is_fullscreen = is_client_fullscreen(w)

          if is_fullscreen and not was_fullscreen then
            fullscreen_windows[w.address] = true
            move_to_fullscreen_ws(w)
          elseif not is_fullscreen and was_fullscreen then
            fullscreen_windows[w.address] = nil
            restore_from_fullscreen_ws(w)
          end

          update_fullscreen_mode()
        end

        hl.on("window.fullscreen", handle_fullscreen)
        hl.on("window.open", handle_fullscreen)
        hl.on("window.close", function(w)
          if fullscreen_windows[w.address] then
            fullscreen_windows[w.address] = nil
            prev_ws[w.address] = nil
            update_fullscreen_mode()
          end
        end)

        -- Fallback: sync state when the active workspace changes.
        hl.on("workspace.active", function(ws)
          if is_fullscreen_ws(ws.name) and count_fullscreen_windows() > 0 then
            hl.dispatch(hl.dsp.submap("fullscreen"))
            set_xremap_fullscreen(true)
          else
            hl.dispatch(hl.dsp.submap("reset"))
            set_xremap_fullscreen(false)
          end
        end)
      '';
    };
    qt_settings = {
      autoLoad = true;
      content = ''
        hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
        hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
      '';
    };
    cursor_settings = {
      autoLoad = true;
      content = ''
        hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
        hl.env("HYPRCURSOR_SIZE", "32")
        hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
        hl.env("XCURSOR_SIZE", "32")
      '';
    };
    panel_windows = {
      autoLoad = true;
      content = ''
        -- size is applied after move, so don't use window_w here
        local panel_position = { "monitor_w-920", "48" }

        hl.window_rule({
          name = "nmrs-float",
          match = { class = "org.nmrs.ui" },
          float = true,
          size = { 900, 650 },
          move = panel_position,
        })

        hl.window_rule({
          name = "pavucontrol-float",
          match = { title = "Volume Control" },
          float = true,
          size = { 900, 550 },
          move = panel_position,
        })
      '';
    };
    steam_workspace = {
      autoLoad = true;
      content = ''
        hl.workspace_rule({
          workspace = "name:steam",
          layout = "master",
        })

        hl.window_rule({
          name = "steam-main",
          match = { class = "steam", title = "^Steam$" },
          workspace = "name:steam",
          no_initial_focus = true
         })

        hl.window_rule({
          name = "steam-friends",
          match = { class = "[Ss]team", title = "^Friends" },
          workspace = "name:steam",
          float = true,
          size = { 320, "monitor_h" },
          move = { "monitor_w-320", "0" },
          no_initial_focus = true
         })

        hl.window_rule({
          name = "battlenet-launcher",
          match = { class = "steam_app_0", title = "^Battle.net$" },
          workspace = "name:battlenet",
          no_initial_focus = true,
          focus_on_activate = false
         })

        hl.window_rule({
          name = "wow-flicker-fix",
          match = { class = "Wow.*" },
          workspace = "name:battlenet",
          fullscreen = true,
        })

        hl.window_rule({
          name = "wow-flicker-fix-steam",
          match = { class = "steam_app_0", title = "^World of Warcraft" },
          workspace = "name:battlenet",
          fullscreen = true,
        })
      '';
    };
    sound_controls = {
      autoLoad = true;
      content = ''
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      '';
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
  xdg.configFile."xremap/normal.yaml".text = lib.generators.toYAML { } normalXremapConfig;
  xdg.configFile."xremap/fullscreen.yaml".text = lib.generators.toYAML { } fullscreenXremapConfig;

  services.xremap = {
    enable = true;
    withHypr = true;
    yamlConfig = lib.generators.toYAML { } normalXremapConfig;
  };

  systemd.user.services.xremap.Service = {
    ExecStart = lib.mkForce
      "${lib.getExe config.services.xremap.package} --watch=config ${config.xdg.configHome}/xremap/active.yaml";
    ExecStartPre = [
      "${pkgs.coreutils}/bin/cp -f ${config.xdg.configHome}/xremap/normal.yaml ${config.xdg.configHome}/xremap/active.yaml"
    ];
  };

  wayland.windowManager.hyprland.submaps.fullscreen = {
    settings.bind = [
      {
        _args = [
          "CTRL + SUPER + F"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"previous\"}")
        ];
      }
      {
        _args = [
          "SUPER + Q"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"true\")")
        ];
      }
    ];
  };

  services.dunst = {
    enable = true;
    settings = {

    };
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      {
        layer = "top";
        modules-left = [
          "custom/session"
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "hyprland/language"
          "pulseaudio"
          "network"
          "tray"
          "clock"
        ];
        clock = {
          interval = 1;
          format = "{:%a %b %d  %H:%M}";
          format-alt = "{:%Y-%m-%d}";
        };
        "custom/session" = {
          format = "";
          tooltip = false;
          menu = "on-click";
          menu-file = "${homeDirectory}/.config/waybar/power_menu.xml";
          menu-actions = {
            exit = "uwsm-app hyprshutdown -- -t 'Exiting hyprland...'";
            restart = "uwsm-app hyprshutdown -- -t 'Restarting...' --post-cmd 'reboot'";
            shutdown = "uwsm-app hyprshutdown -- -t 'Shutting down...' --post-cmd 'shutdown -P 0'";
          };
        };
        "hyprland/workspaces" = {
          format = "{name} {windows}";
          format-window-separator = " ";
          window-rewrite-default = "󰈙";
          window-rewrite = {
            steam = "󰓓";
            kitty = "";
            discord = "";
            Discord = "";
            foot = "󰊠";
            "google-chrome" = "󰊯";
            "Google-chrome" = "󰊯";
            chromium = "󰊯";
            firefox = "󰈹";
            code = "󰨞";
            cursor = "";
            "Volume Control" = "󰕾";
            "org.nmrs.ui" = "󰖪";
            waybar = "";
          };
          "persistent-workspaces" = {
            "*" = 4;
            "steam" = 1;
            "battlenet" = 1;
          };
        };
        "hyprland/language" = {
          format = "⌨️ {}";
          keyboard-name = "xremap";
          format-en = "US 🇺🇸";
          format-uk = "UA 🇺🇦";
          on-click = "hyprctl switchxkblayout xremap";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "{icon} muted";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
            headphone = "󰋋";
            handsfree = "󰋎";
            headset = "󰋎";
          };
          on-click = "waybar-toggle-class org.pulseaudio.pavucontrol pavucontrol";
          scroll-step = 5;
        };
        network = {
          format-wifi = "{icon}";
          format-ethernet = "{icon}";
          format-disconnected = "{icon}";
          format-icons = {
            wifi = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            ethernet = "󰈀";
            disconnected = "󰤭";
          };
          on-click = "waybar-toggle-class org.nmrs.ui nmrs-gui";
        };
        tray = {
          spacing = 10;
        };
      }
    ];
    # catppuccin/nix only imports color variables; module styling must reference them
    style = ''
      window#waybar,
      #clock,
      #pulseaudio,
      #network,
      #tray,
      #window,
      #custom-session,
      #language {
        font-family: "MesloLGM Nerd Font";
        font-size: 16px;
        font-weight: 600;
      }

      window#waybar {
        background-color: @base;
        color: @text;
      }

      #workspaces,
      #workspaces button {
        font-family: "MesloLGM Nerd Font";
        font-size: 16px;
        font-weight: 600;
      }

      #workspaces {
        background-color: @surface0;
        border-radius: 10px;
        margin: 4px 0px 4px 0px;
      }

      #workspaces button {
        color: @overlay1;
        padding: 0 16px 0 10px;
        border-radius: 10px;
        min-height: 0;
      }

      #workspaces button.empty {
        opacity: 0.45;
      }

      #workspaces button.active {
        color: @accent;
        background-color: @surface1;
      }

      #workspaces button:hover {
        background-color: @surface2;
        color: @text;
      }

      #window {
        color: @text;
        background-color: @surface0;
        border-radius: 10px;
        margin: 4px;
        padding: 0 12px;
      }

      #clock,
      #pulseaudio,
      #network,
      #tray {
        background-color: @surface0;
        color: @text;
        border-radius: 10px;
        margin: 4px 2px;
        padding: 0 12px;
      }

      #clock {
        color: @text;
        background: transparent;
        margin-right: 12px;
        padding: 0 4px;
      }

      #pulseaudio {
        color: @maroon;
      }

      #network {
        color: @blue;
      }

      #tray {
        margin-right: 8px;
      }

      #language {
        margin-right: 12px;
      }

      #custom-session {
        background-color: transparent;
        border-radius: 10px;
        margin: 4px 8px 4px 8px;
        padding: 0 8px;
        color: @accent;
      }

      #custom-session:hover {
        background-color: @surface1;
        color: @accent;
      }

      menu {
        background-color: @base;
        color: @text;
        border: 1px solid @surface1;
        border-radius: 8px;
        padding: 4px 0;
      }

      menu menuitem {
        padding: 6px 16px;
      }

      menu menuitem:hover {
        background-color: @surface0;
        color: @accent;
      }
    '';
  };
  xdg.configFile."waybar/power_menu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <object class="GtkMenu" id="menu">
        <child>
          <object class="GtkMenuItem" id="exit">
            <property name="label">Exit Hyprland</property>
          </object>
        </child>
        <child>
          <object class="GtkMenuItem" id="restart">
            <property name="label">Restart</property>
          </object>
        </child>
        <child>
          <object class="GtkMenuItem" id="shutdown">
            <property name="label">Shutdown</property>
          </object>
        </child>
      </object>
    </interface>
  '';

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
  xdg.configFile."uwsm/env".text = ''
    export GTK_THEME=catppuccin-mocha-blue-standard
    export XCURSOR_THEME=catppuccin-mocha-blue-cursors
    export XCURSOR_SIZE=32
    export HYPRCURSOR_THEME=catppuccin-mocha-blue-cursors
    export HYPRCURSOR_SIZE=32
  '';
  xdg.configFile."uwsm/env-hyprland".text = ''
    export HYPRCURSOR_THEME=catppuccin-mocha-blue-cursors
    export HYPRCURSOR_SIZE=32
    export XCURSOR_THEME=catppuccin-mocha-blue-cursors
    export XCURSOR_SIZE=32
  '';
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.hyprpolkitagent.enable = true;

}
