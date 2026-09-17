{ stdenvNoCC, fetchzip, lib }:

stdenvNoCC.mkDerivation rec {
  pname = "telegram-mac";
  version = "12.10.282985";

  src = fetchzip {
    url = "https://osx.telegram.org/updates/Telegram-${version}.app.zip";
    hash = "sha256-aknRqjc9JTN9E5dyhteWj5cT3NVwTdta+9+pGiHewKA=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R ./Telegram.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Official Telegram for macOS (Swift / AppKit)";
    homepage = "https://macos.telegram.org/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
