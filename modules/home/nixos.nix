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
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.window.close({ name = \"title:^($title)$\" })"
    else
      "$@" &
    fi
  '';

in
{

  home.packages = with pkgs; [
    hyprlauncher
    steam
    dunst
    catppuccin-gtk
    networkmanagerapplet
    lxqt.pavucontrol-qt
    nmrs-gui
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    catppuccin-kvantum
    waybarToggleTitle
    waybarToggleClass
    hyprshutdown
    wl-clipboard
    wl-clipboard-x11
  ];
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha";
      package = pkgs.catppuccin-gtk;
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
          "SUPER + Q"
          (lib.generators.mkLuaInline "hl.dsp.window.close()")
        ];
      }
      {
        _args = [
          "SUPER + SPACE"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"hyprlauncher\")")
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
          "SUPER + SHIFT + 1"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 1, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + 2"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 2, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + 3"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 3, follow = true}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + 4"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = 4, follow = true}")
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
          "SUPER + SHIFT + h"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"l\"}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + j"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"d\"}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + k"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"u\"}")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + l"
          (lib.generators.mkLuaInline "hl.dsp.window.swap{direction = \"r\"}")
        ];
      }
      {
        _args = [
          "CTRL + RIGHT"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"e+1\", on_current_monitor = true}")
        ];
      }
      {
        _args = [
          "CTRL + LEFT"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"e-1\", on_current_monitor = true}")
        ];
      }
      {
        _args = [
          "CTRL + SHIFT + RIGHT"
          (lib.generators.mkLuaInline "hl.dsp.window.move{workspace = \"e+1\", follow = true}")
        ];
      }
      {
        _args = [
          "CTRL + SHIFT + LEFT"
          (lib.generators.mkLuaInline "hl.dsp.focus{workspace = \"e-1\", follow = true }")
        ];
      }
      {
        _args = [
          "CTRL + SUPER + F"
          (lib.generators.mkLuaInline "hl.dsp.workspace.toggle_special(\"fullscreen\")")
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
        local FULLSCREEN_WS = "special:fullscreen"
        local prev_ws = {}

        local function is_client_fullscreen(w)
          -- State 2 = fullscreen, 3 = maximize+fullscreen. State 1 (maximized) is SUPER+G — leave it alone.
          return w.fullscreen_client >= 2
        end

        local function move_to_fullscreen_ws(w)
          if not w.workspace or w.workspace.name == FULLSCREEN_WS then
            return
          end
          prev_ws[w.address] = w.workspace.name
          hl.dispatch(hl.dsp.window.move({
            window = "address:" .. w.address,
            workspace = FULLSCREEN_WS,
            follow = true,
          }))
        end

        local function restore_from_fullscreen_ws(w)
          local dest = prev_ws[w.address]
          if not dest then
            return
          end
          prev_ws[w.address] = nil
          hl.dispatch(hl.dsp.window.move({
            window = "address:" .. w.address,
            workspace = dest,
            follow = false,
          }))
        end

        local function handle_fullscreen(w)
          if is_client_fullscreen(w) then
            move_to_fullscreen_ws(w)
          else
            restore_from_fullscreen_ws(w)
          end
        end

        hl.on("window.fullscreen", handle_fullscreen)
        hl.on("window.open", handle_fullscreen)
        hl.on("window.close", function(w)
          prev_ws[w.address] = nil
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
  services.hyprlauncher = {
    enable = true;
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
          format = "{id} {windows}";
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
          };
        };
        "hyprland/language" = {
          format = "⌨️ {}";
          keyboard-name = "logitech-usb-receiver";
          format-en = "US 🇺🇸";
          format-uk = "UA 🇺🇦";
          on-click = "hyprctl switchxkblayout logitech-usb-receiver";
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
          on-click = "waybar-toggle-title \"Volume Control\" pavucontrol-qt";
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
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "blue";
    cursors = {
      enable = true;
    };
    gtk.icon.enable = true;
  };
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-blue-cursors";
    size = 32;
  };
  home.sessionVariables = {
    GTK_THEME = "Catppuccin-Mocha";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };
  xdg.configFile."uwsm/env".text = ''
    export GTK_THEME=Catppuccin-Mocha
    export XCURSOR_THEME=catppuccin-mocha-mauve-cursors
    export XCURSOR_SIZE=32
    export HYPRCURSOR_THEME=catppuccin-mocha-mauve-cursors
    export HYPRCURSOR_SIZE=32
  '';
  xdg.configFile."uwsm/env-hyprland".text = ''
    export HYPRCURSOR_THEME=catppuccin-mocha-mauve-cursors
    export HYPRCURSOR_SIZE=32
    export XCURSOR_THEME=catppuccin-mocha-mauve-cursors
    export XCURSOR_SIZE=32
  '';
}
