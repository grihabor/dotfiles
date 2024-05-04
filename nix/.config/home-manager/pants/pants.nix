{
  lib,
  fetchFromGitHub,
  python39,
  rustPlatform,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "pants";
  version = "release_2.20.0";

  src = fetchFromGitHub {
    owner = "pantsbuild";
    repo = "pants";
    rev = version;
    hash = "sha256-tzpeYxzDfHbDkGAOCXjQfaLf6834c34zJS3DwahSMwI=";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "";
    sourceRoot = "${pname}-${version}/${cargoRoot}";
  };

  cargoRoot = "src/rust/engine";

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
  ];

  configurePhase = ''
    find $cargoDeps
  '';
}
