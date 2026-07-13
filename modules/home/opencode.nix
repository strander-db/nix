{ config, lib, pkgs, ... }:
let
  modelRouter = pkgs.opencode-model-router;
  pluginsDir = "${config.xdg.configHome}/opencode/plugins";
  routerDir = "${pluginsDir}/opencode-model-router";
  routerWrapper = "${pluginsDir}/opencode-model-router.ts";
in
{
  programs.opencode = {
    enable = true;
    settings = {
      # Use the opencode-go provider variant of Kimi K2.7 Code.
      model = "opencode-go/kimi-k2.7-code";
      autoshare = false;
      autoupdate = true;
      # The model-router plugin is auto-discovered from
      # ~/.config/opencode/plugins/ (see home.activation below). Listing it
      # here as a file:// URL does not work in current OpenCode versions.
      plugin = [ ];
    };
  };

  # The plugin source must be a real copy (not a symlink) in the plugins dir so
  # Bun module resolution can find ~/.config/opencode/node_modules/@opencode-ai/plugin.
  # The wrapper .ts file also must be a regular file; a symlink is ignored by
  # OpenCode's plugin loader.
  home.activation.installOpencodeModelRouter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${pluginsDir}"
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG "${routerDir}"
    $DRY_RUN_CMD cp -r ${modelRouter} "${routerDir}"
    $DRY_RUN_CMD chmod -R u+w "${routerDir}"
    $DRY_RUN_CMD rm -f "${routerWrapper}"
    $DRY_RUN_CMD cat > "${routerWrapper}" <<'EOF'
    export { default } from "./opencode-model-router/src/index.ts";
    EOF
    $DRY_RUN_CMD chmod u+w "${routerWrapper}"
  '';
}
