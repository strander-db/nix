{ stdenvNoCC, fetchzip, lib }:

stdenvNoCC.mkDerivation rec {
  pname = "yabai-indicator";
  version = "0.3.4";

  src = fetchzip {
    url = "https://github.com/xiamaz/YabaiIndicator/releases/download/${version}/YabaiIndicator-${version}.zip";
    hash = "sha256-esvS1qtCRz9gJjbhAfeIcZTznoza717/sad3SRR5//U=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R ./YabaiIndicator-${version}/YabaiIndicator.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "macOS menubar applet for showing and switching yabai spaces";
    homepage = "https://github.com/xiamaz/YabaiIndicator";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
