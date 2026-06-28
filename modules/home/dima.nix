{
  config,
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

let
  tideConfigureCmd = import ./fish/tide_vars.nix;
  tideConfigureHash = builtins.hashString "sha256" tideConfigureCmd;
  tideConfigureFish = pkgs.writeText "tide-configure.fish" ''
    set -p fish_function_path ${pkgs.fishPlugins.tide.src}/functions
    ${tideConfigureCmd}
  '';
in
{

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fish
    helix
    difftastic
    bat
    ripgrep
    fzf
    nil
    nixd
    direnv
    nix-direnv
    home-manager
    google-chrome
    code-cursor
    cursor-cli
    chatgpt-cli
    ayugram-desktop
    discord
    fishPlugins.tide
    fishPlugins.done
    fishPlugins.autopair
    fishPlugins.puffer
    fastfetch
    ttyper
    kitty
    emoji-picker
  ];

  programs.fastfetch = {
    enable = true;
  };

  programs.man.package = pkgs.man;

  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];
    settings = {
      user = {
        name = "Dmytro Burkanov";
        email = "dimitchik@gmail.com";
      };
      core = {
        autocrlf = "input";
        editor = "hx";
        excludesfile = "${config.xdg.configHome}/git/ignore";
      };
      diff.external = "difft";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
  };

  programs.fish = {
    enable = true;
    generateCompletions = true;

    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
    ];
    # Tide stores config in universal vars; running `tide configure` every shell
    # startup races with the async prompt and breaks rendering after fastfetch.
    interactiveShellInit = ''
      # Fish 4.x: terminal size queries can leave the prompt blank until a keypress.
      contains no-query-term $fish_features; or set -Ua fish_features no-query-term
    '';
    shellAliases = {
      cat = "bat";
      grep = "rg";
    };
    functions = {
      fish_greeting = ''
        fastfetch
        commandline -f repaint
      '';
    };
  };

  home.activation.tideConfigure = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    marker="${config.xdg.cacheHome}/home-manager/tide-${tideConfigureHash}"
    if [ ! -e "$marker" ]; then
      mkdir -p "$(dirname "$marker")"
      ${pkgs.fish}/bin/fish ${tideConfigureFish} >/dev/null 2>&1
      touch "$marker"
    fi
  '';

  programs.bat = {
    enable = true;
  };

  home.shell.enableFishIntegration = true;

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        auto-format = true;
        trim-trailing-whitespace = false;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        file-picker = {
          hidden = false;
        };
      };
    };
    languages =
      let
        helix-ts-langs = [
          "javascript"
          "typescript"
          "jsx"
          "tsx"
        ];
        helix-ts = lang: {
          name = lang;
          language-servers = [
            "typescript-language-server"
            "eslint"
          ];
          formatter = {
            command = "npx";
            args = [
              "prettier"
              "--write"
            ];
          };
        };
      in
      {
        language-server.eslint = {
          command = "${pkgs.eslint}/bin/eslint";
          args = [ "--stdio" ];
        };
        language = map helix-ts helix-ts-langs;
      };
  };

  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
    enableGitIntegration = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "MesloLGM Nerd Font";
      size = 12;
    };
    settings = {
      shell = "${pkgs.fish}/bin/fish --login --interactive";
    };
    keybindings = {
      "cmd+d" = "launch --location=split";
      "cmd+w" = "close_window";
      "ctrl+h" = "neighboring_window left";
      "ctrl+j" = "neighboring_window down";
      "ctrl+k" = "neighboring_window up";
      "ctrl+l" = "neighboring_window right";
      "cmd+c" = "copy_to_clipboard";
      "cmd+v" = "paste_from_clipboard";
    };
  };
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 3";
    flake = "${homeDirectory}/.config/nix";
  };
}
