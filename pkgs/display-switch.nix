{
  lib,
  stdenvNoCC,
  fetchzip,
  libusb1,
  makeWrapper,
  autoPatchelfHook,
  xorg,
  gcc-unwrapped,
}:

let
  version = "1.4.1";

  src =
    if stdenvNoCC.hostPlatform.isDarwin then
      fetchzip {
        url = "https://github.com/haimgel/display-switch/releases/download/${version}/display_switch-v${version}-macos-universal.zip";
        hash = "sha256-5ihwTDoBD81K7K2xPCF/QoKBawPChSWXuaefCH3IMa4=";
        stripRoot = false;
      }
    else if stdenvNoCC.hostPlatform.isLinux then
      fetchzip {
        url = "https://github.com/haimgel/display-switch/releases/download/${version}/display_switch-v${version}-linux-amd64.zip";
        hash = "sha256-VkKmgVTsWPQoKqQR/YDu8rRmL8HNb1luRMUpxgJsOQ0=";
        stripRoot = false;
      }
    else
      throw "display-switch: unsupported platform ${stdenvNoCC.hostPlatform.system}";
in
stdenvNoCC.mkDerivation {
  pname = "display-switch";
  inherit version src;

  nativeBuildInputs =
    [ ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [ makeWrapper ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs =
    [ ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [ libusb1 ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
      libusb1
      xorg.libX11
      xorg.libXi
      gcc-unwrapped.lib
    ];

  installPhase = ''
    runHook preInstall

    install -Dm755 display_switch $out/bin/display_switch

    ${lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
      wrapProgram $out/bin/display_switch \
        --prefix DYLD_LIBRARY_PATH : "${libusb1.out}/lib"
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Switch monitor inputs via DDC/CI when a USB device connects or disconnects";
    homepage = "https://github.com/haimgel/display-switch";
    license = lib.licenses.mit;
    mainProgram = "display_switch";
    platforms = with lib.platforms; linux ++ darwin;
  };
}
