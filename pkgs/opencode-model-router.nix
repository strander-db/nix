{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

let
  version = "1.3.0";
  tiersJson = ../config/opencode/tiers.json;
in
stdenvNoCC.mkDerivation {
  pname = "opencode-model-router";
  inherit version;

  src = fetchFromGitHub {
    owner = "marco-jardim";
    repo = "opencode-model-router";
    rev = "v${version}";
    hash = "sha256-nqdVWDzBD8zv/OsvAVrxA71ox8l0uacQqt4pf1PSJ1U=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r src package.json LICENSE README.md $out/
    cp ${tiersJson} $out/tiers.json

    runHook postInstall
  '';

  meta = {
    description = "OpenCode plugin for automatic model-tier delegation (fast/medium/heavy)";
    homepage = "https://github.com/marco-jardim/opencode-model-router";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
  };
}
