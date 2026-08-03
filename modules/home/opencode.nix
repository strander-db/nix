{ config, lib, pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      # Use the opencode-go provider variant of Kimi K2.7 Code.
      model = "opencode-go/kimi-k2.7-code";
      autoshare = false;
      autoupdate = true;
      # open-cursor (Nomadcxx/opencode-cursor): OpenCode installs the npm
      # package on first run.
      plugin = [ "@rama_nigg/open-cursor@2.5.4" ];
      provider = {
        cursor-acp = {
          name = "Cursor ACP";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://127.0.0.1:32124/v1";
          };
          models = {
            "cursor-acp/auto" = {
              name = "Auto";
            };
          };
        };
      };
    };
  };
}
