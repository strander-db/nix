{ stdenvNoCC, fetchzip, lib }:

stdenvNoCC.mkDerivation rec {
  pname = "nehir";
  version = "0.5.1";

  src = fetchzip {
    url = "https://github.com/apphane-dev/nehir/releases/download/v${version}/Nehir-${version}.zip";
    hash = "sha256-3yILi4ahsBJWoO4dwlVrRvTbLQMAdoN0uEb2+Nu8fgU=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications" "$out/bin"
    cp -R ./Nehir.app "$out/Applications/"
    ln -s "$out/Applications/Nehir.app/Contents/MacOS/nehirctl" "$out/bin/nehirctl"

    runHook postInstall
  '';

  meta = {
    description = "Scrolling tiling window manager for macOS (Niri-style columns)";
    homepage = "https://github.com/Guria/Nehir";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
